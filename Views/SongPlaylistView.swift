//
//  SongPlaylistView.swift
//  music
//
//  Created by Anel Torić on 18. 3. 26.
//

import SwiftUI
import SwiftData
import Foundation

struct SongPlaylistView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    var onDelete: () -> Void
    var user: User{
        authManager.currentUser!
    }
    var isPlaylistSong:Bool {
        audioManager.playlistTitle == playlist.name && audioManager.currentSong?.title == song.title
    }
    var song:Song
    var parsedComponets:[Substring] {
        song.title.split(separator: " - "
        )
    }

    var displayName: String{
        parsedComponets[0] + " - "  + parsedComponets[1]
    }
    var order:Int
    var playlist:Playlist
    var entry: PlaylistSongs
    @Environment(\.modelContext) private var context
    var body: some View {
        HStack(spacing: 10){
            
           
                if let url = resolveCoverURL(for: song){
                    AsyncCover(song: song, size: 52)
                            } else {
                                Image(systemName: "music.note")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .foregroundColor(.gray)
                            }
                        
             
            VStack(alignment: .leading){
                Text(parsedComponets[0])
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(isPlaylistSong ? .green : .white).lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity,alignment: .leading).clipped().contentShape(Rectangle())
                Text(parsedComponets[1])
                    .foregroundColor(isPlaylistSong ? .green : .gray).lineLimit(1).truncationMode(.tail).font(.system(size: 14, weight: .medium)).clipped().frame(maxWidth: .infinity,alignment: .leading)
            }
            HStack{
                Menu {
                    NavigationLink(destination: AddSongPlaylistView(song: song)){
                        Label("Add to playlist",systemImage: "plus.circle")
                    }
                    Button("Remove from playlist",systemImage: "minus.circle", action: removefromPlaylist)
                    if(!user.blockedSongs.contains(where: {$0.id == song.id})){
                        Button("Block song", systemImage: "play.slash.fill", action:
                                { hideSong(isBlocked: false)
                        })
                    }
                    else{
                        Button("Unblock song", systemImage: "play.fill", action:
                                {
                            hideSong(isBlocked:true)
                        })
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3).foregroundColor(.secondary)
                }.padding(.trailing).compositingGroup()
            }.buttonStyle(PlainButtonStyle())
        } .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                DispatchQueue.main.async{
                    removefromPlaylist()
                }
            } label: {
                Label("Delete", systemImage: "trash.circle.fill")
            }
           
        }
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    
    
      
        
    }
    func removefromPlaylist() {
        context.delete(entry)

        let remaining = playlist.entries
            .filter { $0.id != entry.id }
            .sorted { $0.order < $1.order }

        for (index, item) in remaining.enumerated() {
            item.order = index
        }

        try? context.save()
        onDelete()
    }
    func hideSong(isBlocked:Bool){
    if(isBlocked){
        user.blockedSongs.append(song)
    }
    else{
        user.blockedSongs.removeAll{
            $0.id == song.id
        }
    }
    try? context.save()
    
}
    func formatArtists(_ artists: [Artist]) -> String {
        var artistText: String = ""
        if (!artists.isEmpty){
            for artist in artists {
                artistText += artist.name + ", "
            }
            artistText.removeLast(2)
        }
        return artistText
        }


struct SongHeaderView: View {
        let song: Song
    var parsedComponets: [Substring] { song.title.split(separator: " - ")}
    var displayName: String{
        parsedComponets[0] + " - "  + parsedComponets[1]
    }
        var body: some View {
            HStack(spacing: 16) {
                
                ZStack {
                    AsyncCover(song: song, size: 60)
                }
                .cornerRadius(8)
                .clipped()
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(parsedComponets[0])
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(parsedComponets[1])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            Spacer()
        }
        func formatArtists(_ artists: [Artist]) -> String {
            var artistText: String = ""
            for artist in artists {
                artistText += artist.name + ", "
            }
            artistText.removeLast(2)
            return artistText
        }
        
    }
    
    
struct PlaylistSelectionRow: View {
        let playlist: Playlist
        let isSelected: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                
                ZStack {
                    if playlist.name == "Liked Songs" {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.purple, .pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.white)
                        
                    } else {
                        PlaylistCoverViewAdd(playlist: playlist)
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 14, weight: .medium))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(playlist.entries.count) songs")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .transition(.scale)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
    }
    
    struct PlaylistCoverViewAdd: View {
        let playlist: Playlist
        
        var body: some View {
            GeometryReader { geometry in
                let size = geometry.size.width / 2
                let songs = Array(playlist.entries.map(\.song).prefix(4))
                
                if songs.isEmpty {
                    Color.gray
                } else {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(songs.prefix(2)) { song in
                                SongCoverImageAdd(song: song, size: size)
                            }
                        }
                        HStack(spacing: 0) {
                            ForEach(songs.suffix(2)) { song in
                                SongCoverImageAdd(song: song, size: size)
                            }
                        }
                    }
                }
            }
            .cornerRadius(4)
            .clipped()
        }
    }
    
    struct SongCoverImageAdd: View {
        let song: Song
        let size: CGFloat
        var parsedComponets:[String] {song.title.split(separator: " - ") as! [String] as! [String] as! [String] as! [String] as! [String]}

        var displayName: String{
            parsedComponets[0] + " - "  + parsedComponets[1]
        }
        var body: some View {
            AsyncCover(song: song, size: size)
        }
    }
    
    
    
}

