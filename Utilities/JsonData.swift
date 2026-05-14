//
//  JsonData.swift
//  music
//
//  Created by Anel Torić on 27. 2. 26.
//
import SwiftData
import Foundation


struct SongJSON: Codable{
    let id : Int
    let title: String
    let coverPath: String
    let filePath: String
    let genre_id: Int
    enum CodingKeys: String, CodingKey {
            case id = "id_song"
            case title = "name"
            case coverPath = "cover_path"
            case filePath = "file_path"
            case genre_id
            
        }
}
struct ArtistJSON: Codable{
    let id_artist: Int
    let name: String
}
struct SongArtistJSON: Codable{
    let song_id: Int
    let artist_id: Int
}
struct GenreJSON: Codable{
    let id_genre: Int
    let name: String
}
struct SongsWrapper: Codable {
    let song: [SongJSON]
}

struct ArtistsWrapper: Codable {
    let artists: [ArtistJSON]
}

struct GenresWrapper: Codable {
    let genre: [GenreJSON]
}

struct SongArtistsWrapper: Codable {
    let song_artist: [SongArtistJSON]
}


func importData(context: ModelContext) {
    do {
        
        guard let songsURL = Bundle.main.url(forResource: "song", withExtension: "json"),
              let artistURL = Bundle.main.url(forResource: "artists", withExtension: "json"),
              let genresURL = Bundle.main.url(forResource: "genre", withExtension: "json"),
              let songArtistsURL = Bundle.main.url(forResource: "song_artist", withExtension: "json") else {
            print("Error: One or more JSON files missing")
            return
        }

      
        let songsData = try Data(contentsOf: songsURL)
        let artistsData = try Data(contentsOf: artistURL)
        let genresData = try Data(contentsOf: genresURL)
        let songArtistsData = try Data(contentsOf: songArtistsURL)

        let songWrapper = try JSONDecoder().decode(SongsWrapper.self, from: songsData)
        let artistWrapper = try JSONDecoder().decode(ArtistsWrapper.self, from: artistsData)
        let genreWrapper = try JSONDecoder().decode(GenresWrapper.self, from: genresData)
        let songArtistWrapper = try JSONDecoder().decode(SongArtistsWrapper.self, from: songArtistsData)

       
        var genreMap: [Int: Genre] = [:]
        var artistMap: [Int: Artist] = [:]
        var songMap: [Int: Song] = [:]

       
        for genreJSON in genreWrapper.genre {
            let genre = Genre(name: genreJSON.name)
            context.insert(genre)
            genreMap[genreJSON.id_genre] = genre
        }

      
        for artistJSON in artistWrapper.artists {
            let artist = Artist(name: artistJSON.name)
            context.insert(artist)
            artistMap[artistJSON.id_artist] = artist
        }

      
        for songJSON in songWrapper.song {
            let song = Song(title: songJSON.title, filepath: songJSON.filePath, coverpath: songJSON.coverPath)
            song.genre = genreMap[songJSON.genre_id]
            context.insert(song)
            songMap[songJSON.id] = song
        }

       
        var missingSongs = Set<Int>()
        var missingArtists = Set<Int>()

        for songArtist in songArtistWrapper.song_artist {
            if let song = songMap[songArtist.song_id] {
                if let artist = artistMap[songArtist.artist_id] {
                    song.addArtist(artist)
                } else {
                    missingArtists.insert(songArtist.artist_id)
                }
            } else {
                missingSongs.insert(songArtist.song_id)
            }
        }

        try context.save()

       
        if !missingSongs.isEmpty {
            print("Warning: \(missingSongs.count) songs referenced in song_artist.json not found in song.json")
            print("Missing song IDs: \(Array(missingSongs).sorted())")
        }

        if !missingArtists.isEmpty {
            print("Warning: \(missingArtists.count) artists referenced in song_artist.json not found in artists.json")
            print("Missing artist IDs: \(Array(missingArtists).sorted())")
        }

        print("Import completed successfully!")

    } catch {
        print("Error importing data: \(error)")
    }
}

