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

struct ArtistSearchView: View {
    var artist: Artist
    @Query(sort: \ArtistSearchHistory.date, order: .reverse)
    private var searches: [ArtistSearchHistory]
    @EnvironmentObject var auth:AuthManager
    var user:User{
        auth.currentUser!
    }
    @Query private var latestSongsByArtist: [Song]
    @Environment(\.modelContext)  var context
    

    
    init(artist: Artist) {
        self.artist = artist
        let artistID = artist.id
        self._latestSongsByArtist = Query(
            filter: #Predicate<Song> { song in
                song.artists.contains(where: { $0.id == artistID })
            },
            sort: \Song.persistentModelID,
            order: .reverse
        )
    }
    
    var body: some View {
        HStack {
            if((auth.currentUser!.blockedArtists.contains(where:{$0.id == artist.id}))){
                ZStack {
                    Image(latestSongsByArtist.first!.coverpath)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 75, height: 75)
                        .cornerRadius(100)
                        .opacity(1)
                    Image(systemName: "slash.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    
                }
                
            }else{
                if let firstMatch = latestSongsByArtist.first {
                    Image(firstMatch.coverpath)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .cornerRadius(100)
                }
            }
                Text(artist.name)
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Menu {
                    
                    if !user.followedArtists.contains(where:{
                        artist.id == $0.id
                    }){
                        Button("Follow artist",systemImage:"person.fill.checkmark",action: { followArtist() } )
                    }
                    else{
                        Button("Unfollow artist",systemImage:"person.fill.xmark",action:{ unfollowArtist()})
                    }
                    if !user.blockedArtists.contains(where:{
                        artist.id == $0.id
                    }){
                        Button("Block artist", systemImage: "person.slash.fill", action:{ blockArtist() })
                        
                    }
                    else{
                        Button("Unblock artist", systemImage: "person.circle.fill", action: {unblockArtist()})
                    }
                }
                label:  {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
        }.padding(.bottom,10).padding(.horizontal)
            
        }
            
         func blockArtist(){
             user.blockedArtists.append(artist)
             user.followedArtists.removeAll{
                 artist.id == $0.id
             }
             let descriptor = FetchDescriptor<Playlist>()
             if let playlists = try? context.fetch(descriptor) {
                 for playlist in playlists {
                     playlist.entries.removeAll { $0.song.artists.contains(artist) }
                 }
             }
     
            try? context.save()
        }
         func followArtist(){
            user.followedArtists.append(artist)
             user.blockedArtists.removeAll{
                 artist.id == $0.id
             }
            try? context.save()
        }
         func unblockArtist(){
             user.blockedArtists.removeAll(){
                 artist.id == $0.id
             }
            try? context.save()
        }
        func unfollowArtist(){
            user.followedArtists.removeAll(){
                artist.id == $0.id
            }
            try? context.save()
        }
    func performSearchArtist(artist:Artist){
       
        if let exists = searches.first(where: { $0.artist == artist}){
            context.delete(exists)
        }
        user.artistSearchHistory.append(ArtistSearchHistory(artist: artist,user: user))
        do{
            try context.save()
        } catch{
            print("Failed to save \(error)")
        }
    }
        

    }
