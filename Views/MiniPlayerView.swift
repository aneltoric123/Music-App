//
//  MiniPlayerView.swift
//  music
//
//  Created by Anel Torić on 17. 3. 26.
//

import SwiftData
import SwiftUI
import Foundation

struct MiniPlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var context
    @State private var queueAnimation: Bool = false
    @Binding var navPath: NavigationPath
    
    var likedSongsPlaylist: Playlist { authManager.likedSongsPlaylist! }
    var likedSongs: [Song] { likedSongsPlaylist.songs }
    
    var body: some View {
        if let currentSong = audioPlayer.currentSong {
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .center, spacing: 14) {
                    
                    Button {
                        queueAnimation = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            navPath.append(Route.queue)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Album Cover
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .blur(radius: 8)
                                
                                AsyncCover(song: currentSong, size: 50)
                                    
                            }
                            
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(parsedComponents[0])
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text(parsedComponents[1])
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            .frame(minWidth:75,maxWidth: .infinity,alignment: .leading)
                            
                            
                            Button {
                                likeSong(song: currentSong)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Image(systemName: likedSongs.contains(currentSong) ? "heart.fill" : "heart")
                                    .font(.system(size: 18))
                                    .foregroundColor(likedSongs.contains(currentSong) ? .pink : .gray)
                                    .scaleEffect(likedSongs.contains(currentSong) ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likedSongs.contains(currentSong))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    
                   
                    
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            audioPlayer.playPrevious()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 14))
                                .foregroundColor(audioPlayer.currentIndex != 0 ? .white : .gray.opacity(0.5))
                        }
                        .disabled(audioPlayer.currentIndex == 0)
                        
                        Button(action: {
                            audioPlayer.togglePlayPause()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Button(action: {
                            audioPlayer.playNext()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14))
                                .foregroundColor(audioPlayer.currentIndex + 1 != audioPlayer.playlist.count ? .white : .gray.opacity(0.5))
                        }
                        .disabled(audioPlayer.currentIndex + 1 == audioPlayer.playlist.count)
                        Button{
                            if(audioPlayer.isPlaying){
                                audioPlayer.togglePlayPause()
                            }
                            audioPlayer.stopQueue()
                        }
                        label:{
                            Image(systemName:"xmark").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 3)
                        
                        Rectangle()
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(geo.size.width, (audioPlayer.currentTime / max(0.001, audioPlayer.totalDuration)) * geo.size.width)), height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1.5))
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .offset(x: max(0, min(geo.size.width, (audioPlayer.currentTime / max(0.001, audioPlayer.totalDuration)) * geo.size.width)) - 6, y: 0)
                            .opacity(audioPlayer.isPlaying ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: audioPlayer.isPlaying)
                    }
                }
                .frame(height: 20)
                .onChange(of: audioPlayer.currentTime) { newValue in
                    if audioPlayer.totalDuration.isFinite && !audioPlayer.totalDuration.isNaN {
                        if newValue >= audioPlayer.totalDuration - 0.5 {
                            if audioPlayer.currentIndex < audioPlayer.playlist.count - 1 {
                                audioPlayer.playNext()
                            } else {
                                audioPlayer.stopQueue()
                            }
                        }
                    }
                }
                
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            
            .background(
                UltraThinMaterial()
                    .ignoresSafeArea(edges: .bottom)
            )
            
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                )
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: queueAnimation)
        }
        
    }
    
    private var parsedComponents: [String] {
        audioPlayer.currentSong?.title.components(separatedBy: " - ") ?? []
    }
    
    @MainActor func likeSong(song: Song) {
        if likedSongs.contains(song) {
            likedSongsPlaylist.entries.removeAll(where: { $0.song.title == song.title })
            try? context.save()
        } else {
            likedSongsPlaylist.entries.append(PlaylistSongs(order: likedSongsPlaylist.entries.count, playlist: likedSongsPlaylist, song: song))
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

struct UltraThinMaterial: View {
    var body: some View {
        Color.black.opacity(0.7)
            .background(.ultraThinMaterial)
    }
}
