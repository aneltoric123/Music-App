//
//  Untitled.swift
//  music
//
//  Created by Anel Torić on 13. 3. 26.
//

//
//  ArtistSearchview.swift
//  music
//
//  Created by Anel Torić on 11. 3. 26.
//

//
//  SongSearchView.swift
//  music
//
//  Created by Anel Torić on 5. 3. 26.
//

//
//  SongCoverView.swift
//  music
//
//  Created by Anel Torić on 5. 3. 26.
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
        NavigationLink(destination: ArtistView(artist: artist,isSearch: false),)
        {
            HStack(spacing: 10){
                if let firstMatchArtist = latestSongsByArtist.first(where: {
                    song in
                    !song.artists.isEmpty && song.artists[0].name == artist.name
                })
                {
                Image(firstMatchArtist.coverpath).resizable().scaledToFit().frame(width:100,height:100).cornerRadius(100)
                        }
                    
                
                VStack(alignment: .leading){
                    Text(artist.name)
                        .foregroundColor(.gray).lineLimit(1).truncationMode(.tail).font(.title).frame(maxWidth: 300,alignment: .leading)
                }
            }.buttonStyle(PlainButtonStyle()).contentShape(Rectangle())
            
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
