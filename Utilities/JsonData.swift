import SwiftData
import Foundation


struct SongJSON: Codable {
    let id_song: Int
    let title: String
    let filepath: String
    let album_id: Int?
    let genre_id: Int?
    let artist_ids: [Int]?
   
    
    enum CodingKeys: String, CodingKey {
        case id_song = "id_song"
        case title
        case filepath
        case album_id
        case genre_id
        case artist_ids
    }
}

struct AlbumJSON: Codable {
    let id_album: Int
    let name: String
    
    let artistIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id_album = "id_album"
        case name
        case artistIds = "artists_ids"
    }
}

struct ArtistJSON: Codable {
    let id: Int
    let name: String
}

struct GenreJSON: Codable {
    let id_genre: Int
    let name: String
}


struct SongsWrapper: Codable {
    let songs: [SongJSON]
}

struct AlbumsWrapper: Codable {
    let albums: [AlbumJSON]
}

struct ArtistsWrapper: Codable {
    let artists: [ArtistJSON]
}

struct GenresWrapper: Codable {
    let genre: [GenreJSON]
}

func importData(context: ModelContext) {
    do {
        
        guard let songsURL = Bundle.main.url(forResource: "song", withExtension: "json"),
              let artistsURL = Bundle.main.url(forResource: "artists", withExtension: "json"),
              let genresURL = Bundle.main.url(forResource: "genre", withExtension: "json"),
              let albumsURL = Bundle.main.url(forResource: "albums", withExtension: "json") else {
            print("Error: One or more JSON files missing from bundle")
            return
        }

        let songsData = try Data(contentsOf: songsURL)
        let artistsData = try Data(contentsOf: artistsURL)
        let genresData = try Data(contentsOf: genresURL)
        let albumsData = try Data(contentsOf: albumsURL)

        
        func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
            if let result = try? JSONDecoder().decode(T.self, from: data) {
                return result
            }
            return nil
        }

        
        var songArray: [SongJSON] = []
        if let wrapper = decode(SongsWrapper.self, from: songsData) {
            songArray = wrapper.songs
        } else if let direct = decode([SongJSON].self, from: songsData) {
            songArray = direct
        } else {
            throw NSError(domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse songs.json"])
        }

        
        var artistArray: [ArtistJSON] = []
        if let wrapper = decode(ArtistsWrapper.self, from: artistsData) {
            artistArray = wrapper.artists
        } else if let direct = decode([ArtistJSON].self, from: artistsData) {
            artistArray = direct
        } else {
            throw NSError(domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse artists.json"])
        }

        
        var genreArray: [GenreJSON] = []
        if let wrapper = decode(GenresWrapper.self, from: genresData) {
            genreArray = wrapper.genre
        } else if let direct = decode([GenreJSON].self, from: genresData) {
            genreArray = direct
        } else {
            throw NSError(domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse genre.json"])
        }

        
        var albumArray: [AlbumJSON] = []
        if let wrapper = decode(AlbumsWrapper.self, from: albumsData) {
            albumArray = wrapper.albums
        } else if let direct = decode([AlbumJSON].self, from: albumsData) {
            albumArray = direct
        } else {
            throw NSError(domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse albums.json"])
        }

        
        var genreMap: [Int: Genre] = [:]
        var artistMap: [Int: Artist] = [:]
        var albumMap: [Int: Album] = [:]

        
        for json in genreArray {
            
            let descriptor = FetchDescriptor<Genre>(
                predicate: #Predicate { genre in
                    genre.id_genre == json.id_genre
                }
            )
            var genre = try context.fetch(descriptor).first
            
            if genre == nil {
                
                genre = Genre(id: json.id_genre, name: json.name)
                context.insert(genre!)
            }
            genreMap[json.id_genre] = genre!
        }

       
        for json in artistArray {
            let descriptor = FetchDescriptor<Artist>(predicate: #Predicate { $0.id == json.id })
            var artist = try context.fetch(descriptor).first
            
            if artist == nil {
                
                artist = Artist(id: json.id, name: json.name)
                context.insert(artist!)
            }
            artistMap[json.id] = artist!
        }
        
        
        for json in albumArray {
            let descriptor = FetchDescriptor<Album>(predicate: #Predicate { $0.id_album == json.id_album })
            var album = try context.fetch(descriptor).first
            
            if album == nil {
                
                album = Album(id: json.id_album, name: json.name)
                context.insert(album!)
            }
            
            
            if let ids = json.artistIds {
                var linkedArtists: [Artist] = []
                for aid in ids {
                    if let artist = artistMap[aid] {
                        linkedArtists.append(artist)
                    }
                }
               
                album!.artists.removeAll()
                album!.artists.append(contentsOf: linkedArtists)
            }
            
            albumMap[json.id_album] = album!
        }

        
       
        for json in songArray {
            let descriptor = FetchDescriptor<Song>(
                predicate: #Predicate { $0.id_song == json.id_song }
            )

            var song = try context.fetch(descriptor).first

            if song == nil {
                let newSong = Song(
                    id: json.id_song,
                    title: json.title,
                    filepath: json.filepath
                )
                newSong.primaryArtistId = json.artist_ids![0]
                context.insert(newSong)
                song = newSong
            }

            
            if let genreID = json.genre_id,
               let genre = genreMap[genreID] {
                song!.genre = genre
            }
            
            
            if let albumID = json.album_id,
               let album = albumMap[albumID] {
                song!.album = album
            }

            if let artistIDs = json.artist_ids {
                let linkedArtists = artistIDs.compactMap { artistMap[$0] }

                song!.artists.removeAll()
                song!.artists.append(contentsOf: linkedArtists)
            }
        }
        try context.save()
        
        

        print("Import completed successfully! Imported \(songArray.count) songs.")
        
                
    } catch {
        print("Error importing data: \(error.localizedDescription)")
    }
}
