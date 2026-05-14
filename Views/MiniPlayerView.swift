//
//  MiniPlayerView.swift
//  music
//
//  Created by Anel Torić on 17. 3. 26.
//

import SwiftData
import SwiftUI
import Foundation

struct MiniPlayerView : View {
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    @Binding var navPath: NavigationPath
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    var body: some View {
        if let currentSong = audioPlayer.currentSong {
            VStack(spacing: 0) {
                Divider()

                HStack {
                 
                    Button {
                        navPath.append(Route.queue)
                    } label: {
                        HStack {
                            let coverName = currentSong.coverpath
                            
                            Image(coverName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                                .cornerRadius(4)

                            VStack(alignment: .leading) {
                                Text(currentSong.title)
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                   
                                   
                                Text(formatArtists(currentSong.artists))
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                   
                                    
                            }
                            Spacer()
                            Button {
                                likeSong(song: currentSong)
                            }
                            label:{
                                if(likedSongs.contains(currentSong)){
                                    Image(systemName: "heart.fill").font(.title2)
                                }
                                else{
                                    Image(systemName: "heart").font(.title2)
                                }
                            }.foregroundColor(.pink)
                        }
                    }.buttonStyle(.plain)
                        .contentShape(Rectangle())

                    Spacer()

                    
                    Button(action: { audioPlayer.playPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                    }.tint(audioPlayer.currentIndex != 0 ?.white :.gray).disabled(audioPlayer.currentIndex == 0)

                    Button(action: { audioPlayer.togglePlayPause() }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }.tint(.white)

                    Button(action: { audioPlayer.playNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                    }.tint(audioPlayer.currentIndex + 1 != audioPlayer.playlist.count ?.white :.gray).disabled(audioPlayer.currentIndex + 1 == audioPlayer.playlist.count)
                }
                .padding(.horizontal)

               
                ProgressView(
                    value: audioPlayer.currentTime,
                    total: audioPlayer.totalDuration
                )
                .padding(.horizontal)
                
               
            }
            
            
            .background(.ultraThinMaterial)
        }
    }
    @MainActor func likeSong(song:Song){
        
        if(likedSongs.contains(song)){
            likedSongsPlaylist.entries.removeAll(where: {$0.song.coverpath == song.coverpath})
            try? context.save()
        }
        else{
            likedSongsPlaylist.entries.append(PlaylistSongs(order:likedSongsPlaylist.entries.count,playlist: likedSongsPlaylist, song: song))
            try? context.save()
            
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else {
            return "0:00"
        }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    private func formatArtists(_ artists: [Artist]) -> String {
        artists.map { $0.name }.joined(separator: ", ")
    }
    
}

