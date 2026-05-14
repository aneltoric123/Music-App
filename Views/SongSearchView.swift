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


struct SongSearchView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    var user : User
    { authManager.currentUser!}
    let onLike: () -> Void
    var song: Song
    var likedSongsPlaylist: Playlist
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @Query(sort: \SongSearchHistory.date,order: .reverse) private var searches: [SongSearchHistory]
    private var isBlocked: Bool {
        user.blockedSongs.contains { $0.id == song.id } ||
        song.artists.contains { a in
            user.blockedArtists.contains { $0.id == a.id }
        }
    }
    @Environment(\.modelContext) private var context
    var body: some View {
        
        HStack {
                HStack(spacing: 10) {
                    let coverName = song.coverpath
                    if(isBlocked){
                        ZStack{
                            Image(coverName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 75, height: 75)
                                .cornerRadius(100)
                                .opacity(1)
                            Image(systemName: "slash.circle.fill") .font(.system(size: 40))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                            
                        }
                    }
                    else{
                        Image(coverName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .cornerRadius(20)
                    }
                        
                    
                    VStack(alignment: .leading) {
                        Text(song.title)
                            .font(.headline).bold()
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(formatArtists(song.artists))
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
            Spacer()
            Button{
            likeSong()
            onLike()
            }
            label:{
                Image(systemName: !likedSongs.contains(song) ? "heart" : "heart.fill") .foregroundColor(.pink)
            }.contentShape(Rectangle())
            
            Menu {
                NavigationLink(destination: AddSongPlaylistView(song: song)) {
                    Label("Add to playlist", systemImage: "plus.circle")
                }
               
                if(!user.blockedSongs.contains(where: {$0.id == song.id})){
                    Button("Block song", systemImage: "play.slash.fill", action: {
                        hideSong(isBlocked: false
                    )}
                    )
                }
                else{
                    Button("Unblock song", systemImage: "play.fill", action: {
                        hideSong(isBlocked: true)
                    }
                    )
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }.compositingGroup()
        }.onTapGesture {
            audioManager.playSong(song, from: [song],isOnlySong: true)
            performSearchSong(song: song)
        }.padding(.bottom,10).padding(.horizontal)
    }
        
        func hideSong(isBlocked:Bool){
        if(!isBlocked){
            likedSongsPlaylist.entries.removeAll { $0.song.id == song.id }
                   let descriptor = FetchDescriptor<Playlist>()
                   if let playlists = try? context.fetch(descriptor) {
                       for playlist in playlists {
                           playlist.entries.removeAll { $0.song.id == song.id }
                       }
                   }
            audioManager.playlist.removeAll { $0.id == song.id }
                   if audioManager.currentSong?.id == song.id {
                       audioManager.playNext()
                   }
            user.blockedSongs.append(song)
        }
        else{
            user.blockedSongs.removeAll{
                $0.id == song.id
            }
        }
        try? context.save()
        
    }
    @MainActor func likeSong(){
        
        if(likedSongs.contains(song)){
            likedSongsPlaylist.entries.removeAll(where: {$0.song.coverpath == song.coverpath})
            try? context.save()
        }
        else{
            likedSongsPlaylist.entries.append(PlaylistSongs(order:likedSongsPlaylist.entries.count + 1,playlist: likedSongsPlaylist, song: song))
            try? context.save()
            
        }
    }
    func performSearchSong(song:Song){
        print("Saved song:", song.title)
        if let exists = searches.first(where: { $0.song.id == song.id }) {
            context.delete(exists)
        }
        let value:SongSearchHistory = SongSearchHistory(song: song,user: authManager.currentUser!)
        user.songSearchHistory.append(value)

        do{
            try context.save()
        } catch{
            print("Failed to save \(error)")
        }
    }
    func formatArtists(_ artists: [Artist]) -> String {
        var artistText: String = ""
        if(artists.count > 1){
            for artist in artists {
                artistText += artist.name + ", "
            }
            artistText.removeLast(2)
        }
        else{
            artistText = artists.first?.name ?? "Anonymous"
        }
        return artistText
        }
}
