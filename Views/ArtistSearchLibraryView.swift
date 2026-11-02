//
//  Untitled.swift
//  music
//
//  Created by Anel Torić on 13. 3. 26.
//


import SwiftUI
import Foundation
import SwiftData


struct ArtistSearchLibraryView: View {
    var artist: Artist
    @Query(sort: \ArtistSearchHistory.date,order: .reverse)
    private var searches: [ArtistSearchHistory]
    @EnvironmentObject var authManager:AuthManager
    var likedSongsPlaylist: Playlist{
        authManager.likedSongsPlaylist!
    }
    @Query private var latestSongsByArtist: [Song]
       init(artist: Artist) {
           self.artist = artist
           let artistName = artist.name
           self._latestSongsByArtist = Query(
               filter: #Predicate<Song> { song in
                   song.artists.contains(where: { $0.name == artistName })
               },
               sort: \Song.persistentModelID,
               order: .reverse
           )
       }
    @Environment(\.modelContext) private var context
    var body: some View {
        NavigationLink(destination: NewArtist(artist: artist),)
        {
           
                HStack{
                    if let firstMatchArtist = latestSongsByArtist.first(where: {
                        song in
                        !song.artists.isEmpty && song.artists[0].name == artist.name
                    })
                    {
                        AsyncCover(song: firstMatchArtist, size: 100)
                    }
                    
                    
                    
                    VStack(alignment: .leading){
                        Text(artist.name)
                            .foregroundColor(.white)
                            .font(.title)
                            .lineLimit(1)
                            .fontWeight(.regular)
                        Text("Artist").font(.title2).fontWeight(.regular).foregroundColor(.gray)
                    }
                    Spacer()
                }.padding(.horizontal,20)
                
                
            }
        
        
    }
    
    
    func performSearchArtist(artist:Artist){
       
        if let exists = searches.first(where: { $0.artist == artist}){
            context.delete(exists)
        }
        authManager.currentUser?.artistSearchHistory.append(ArtistSearchHistory(artist: artist,user: authManager.currentUser!))
        do{
            try context.save()
        } catch{
            print("Failed to save \(error)")
        }
    }
    
}
