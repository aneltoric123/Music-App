import SwiftUI
import SwiftData
import Foundation
 

struct QueueView: View {
        @EnvironmentObject var audioManager: AudioPlayerManager
        @Binding var navPath: NavigationPath
        
        var body: some View {
                Menu {
                    Button {
                        let songs = Array(audioManager.playlist.suffix(from: audioManager.currentIndex))
                        navPath.append(Route.addQueuePlaylist(songs))
                    } label: {
                        Label("Create Playlist Queue", systemImage: "music.note")
                    }.frame(alignment: .topTrailing)
                    
                    Button {
                        if let song = audioManager.currentSong {
                            navPath.append(Route.song(song))
                        }
                    } label: {
                        Label("View Song", systemImage: "music.note")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }.compositingGroup()
                if let current = audioManager.currentSong {
                    Button{
                        navPath.append(Route.song(current))
                    }
                    label:{
                    VStack() {
                        Text("Now Playing")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            SongCoverViewQueueMain(song: current,navPath: $navPath)
                    }.swipeActions{
                        
                    }
                    }
                }
                
            
            
            ZStack {
                LinearGradient(
                    colors: [.black, .purple.opacity(0.6), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Up Next")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 15) {
                                ForEach(Array(zip(audioManager.playlist.indices,audioManager.playlist)),id: \.0)
                                { index,song in
                                    if song.id != audioManager.currentSong?.id && audioManager.currentIndex < index {
                                        SongRowView(song: song, navPath: $navPath).onTapGesture {
                                            audioManager.currentIndex = index
                                           
                                            audioManager.playSong(song, from: audioManager.playlist, isOnlySong: false)
                                            audioManager.currentIndex = index
                                            
                                        }.contentShape(Rectangle())
                                    }
                                }
                            }
                        }
                    
                }
            }.onAppear{
                audioManager.isShowingMiniPlayer = false
                audioManager.isShowingMiniPlayerBottom = false
            }
        }
    }
    struct SongCoverViewQueueMain: View {
        var song: Song
        var artistText: String {
            song.artists.map { $0.name }.joined(separator: ", ")
        }
        @Binding var navPath: NavigationPath
        @Environment(\.modelContext) private var context
        var body: some View {
                    VStack(spacing: 10){
                        Image(song.coverpath)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                    VStack(spacing: 4){
                        Text(song.title)
                            .font(.subheadline).bold().foregroundColor(.white).frame(width: 200).lineLimit(1).truncationMode(.tail)
                        Text(artistText)
                            .foregroundColor(.gray).frame(width: 300).lineLimit(1).truncationMode(.tail)
                    }
        }
    }
    
    
    struct SongRowView: View {
        var song: Song
        @Binding var navPath: NavigationPath
        
        var body: some View {
            HStack {
                SongCoverViewQueue(song: song, navPath: $navPath)
            }
            .padding()
        }
    }
    struct SongCoverViewQueue: View {
        var song: Song
        @Binding var navPath: NavigationPath
        
        var artistText: String {
            song.artists.map { $0.name }.joined(separator: ", ")
        }
        
        var body: some View {
            HStack {
                Image(song.coverpath)
                    .resizable()
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading) {
                    Text(song.title).foregroundColor(.white)
                    Text(artistText).foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        navPath.append(Route.addSingleSong(song))
                    } label: {
                        Label("Add to playlist", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }.contentShape(Rectangle()).compositingGroup()
            }.contentShape(Rectangle())
        }
    }
    
    struct AddSongsPlaylistView: View {
        var songs: [Song]
        @Binding var navPath: NavigationPath
        @Environment(\.modelContext) private var context
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject var authManager: AuthManager
        @FocusState private var isTextFieldFocused: Bool
        @State private var playlistName = ""
        
        var body: some View {
            ZStack {
                LinearGradient( gradient: Gradient(colors: [ Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.03, green: 0.03, blue: 0.06) ]), startPoint: .top, endPoint: .bottom )
                    .ignoresSafeArea()
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playlist Name") .font(.subheadline) .foregroundColor(.gray)
                        TextField("My Awesome Playlist", text: $playlistName).textFieldStyle(.plain) .padding().focused($isTextFieldFocused).background( RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)) )
                            .overlay( RoundedRectangle(cornerRadius: 10) .stroke(Color.white.opacity(0.2), lineWidth: 1) ) .foregroundColor(.white) .autocorrectionDisabled()
                    } .padding(.horizontal)
                    Button(action: createPlaylist) {
                        Text("Create Playlist") .font(.headline) .foregroundColor(.white) .frame(maxWidth: .infinity) .padding() .background( LinearGradient( gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing ) ) .cornerRadius(12)
                    }
                    .disabled(playlistName.isEmpty).padding(.horizontal).padding(.bottom, 20)
                    Spacer()
                    Button("Cancel"){
                        navPath.removeLast(1)
                        navPath.append(Route.queue)
                    }
                }.onAppear { isTextFieldFocused = true }
            }
        }
        
        private func createPlaylist() {
            let newPlaylist = Playlist(name: playlistName, owner: authManager.currentUser!)
            
            context.insert(newPlaylist)
            
            for (index, song) in songs.enumerated() {
                let entry = PlaylistSongs(
                    order: index,
                    playlist: newPlaylist,
                    song: song)

                context.insert(entry)
                newPlaylist.entries.append(entry)
            }
            
            try? context.save()
            dismiss()
        }
    }
    

