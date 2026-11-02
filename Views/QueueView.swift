import SwiftUI
import SwiftData
import Foundation

struct QueueView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @Binding var navPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @State private var startAnimation: Bool = false
    @State private var isEditMode: Bool = false
    @State private var selectedIndices: Set<Int> = []
    private var safeDuration: Double {
        if audioManager.totalDuration.isFinite &&
           !audioManager.totalDuration.isNaN &&
           audioManager.totalDuration > 0 {
            return audioManager.totalDuration
        }
        return 0
    }
    
    var body: some View {
        ZStack {
           
            LinearGradient(
                colors: [
                    .black,
                    Color(red: 0.08, green: 0.05, blue: 0.15),
                    Color(red: 0.02, green: 0.02, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(.purple.opacity(0.25))
                .frame(width: 300)
                .blur(radius: 100)
                .offset(x: -120, y: -250)
            
            Circle()
                .fill(.cyan.opacity(0.18))
                .frame(width: 250)
                .blur(radius: 100)
                .offset(x: 140, y: 250)
            
            VStack(spacing: 0) {
               
                HStack {
                    Spacer()
                    
                    
                    if isEditMode {
                        
                        Button{
                            selectedIndices = []
                            isEditMode = false
                        }
                        label: {
                            Image(systemName:"arrow.uturn.left").tint(.green).padding().frame(width: 50, height: 50)
                        }
                        Button {
                            deleteSelectedSongs()
                        } label: {
                            Image(systemName: "trash.fill")
                                .tint(.red)
                                .padding()
                                .frame(width: 50, height: 50)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    Menu {
                        Button {
                            let songs = Array(audioManager.playlist.suffix(from: audioManager.currentIndex))
                            navPath.append(Route.addQueuePlaylist(songs))
                        } label: {
                            Label("Create Queue Playlist", systemImage: "music.note")
                        }
                        Button {
                            navPath.append(Route.addSingleSong(audioManager.currentSong!))
                        } label: {
                            Label("Add to playlist", systemImage: "plus.circle")
                        }
                        
                        Button {
                            if let song = audioManager.currentSong {
                                navPath.append(Route.song(song))
                            }
                        } label: {
                            Label("View Song", systemImage: "music.note")
                        }
                       
                        Button{
                            audioManager.currentIndex = 0
                            audioManager.playSong(audioManager.playlist.first!, from: audioManager.playlist, isOnlySong: false)
                        }
                        label:{
                            Label("Rerun Queue",systemImage:"repeat")
                        }
                        Button{
                           
                            audioManager.isPlaying = false
                            audioManager.stopQueue()
                            if(navPath.count > 0){
                                navPath.removeLast()
                            }
                            dismiss()
                        }
                        label:{
                            Label("Stop Queue",systemImage:"xmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .compositingGroup()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        
                        if let current = audioManager.currentSong {
                            Button {
                                navPath.append(Route.song(current))
                            } label: {
                                VStack(spacing: 10) {
                                    Text("Now Playing")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    SongCoverViewQueueMain(song: current)
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                        
                       
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Up Next")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline.bold())
                                .padding(.horizontal)
                            
                            ForEach(filteredUpNextSongs(), id: \.song.id) { item in
                                SongRowView(
                                    song: item.song,
                                    index: item.index,
                                    isSelected: selectedIndices.contains(item.index),
                                    isEditMode: isEditMode, selectedIndices: $selectedIndices,
                                    navPath: $navPath,
                                    onTap: { playSongAt(index: item.index) },
                                    onLongPress: { toggleEditMode(for: item.index) },
                                    onToggleSelect: { toggleSelection(for: item.index) }
                                )
                                .opacity(startAnimation ? 1 : 0)
                                       .offset(x: startAnimation ? 0 : 30)
                                       .animation(
                                           .easeOut(duration: 0.35),
                                           value: startAnimation
                                       )
                            }
                            
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)
                
                Spacer()
                
               
                VStack(spacing: 10) {
                    
                    VStack() {
                        Slider(
                            value: $audioManager.currentTime,
                            in: 0...safeDuration,
                            onEditingChanged: { editing in
                                if !editing {
                                    audioManager.seek(to: audioManager.currentTime)
                                }
                            }
                        )
                        .tint(.white)
                        
                        HStack {
                            Text(formatTime(audioManager.currentTime))
                            Spacer()
                            Text(formatTime(audioManager.totalDuration))
                        }.padding(.horizontal)
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }
                    
                   
                    HStack(spacing: 20) {
                        Spacer()
                        
                        Button {
                            audioManager.playPrevious()
                        } label: {
                            Image(systemName: "backward.fill")
                                .tint(audioManager.currentIndex != 0 ? .white : .gray)
                                .disabled(audioManager.currentIndex == 0)
                        }
                        
                        
                        Button {
                            audioManager.togglePlayPause()
                        } label: {
                            Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .shadow(radius: 10)
                        }
                        .scaleEffect(audioManager.isPlaying ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: audioManager.isPlaying)
                        
                        
                        Button {
                            audioManager.playNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .tint(audioManager.currentIndex + 1 != audioManager.playlist.count ? .white : .gray)
                                .disabled(audioManager.currentIndex + 1 == audioManager.playlist.count)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.2))
                .onAppear {
                    audioManager.isShowingMiniPlayer = false
                    audioManager.isShowingMiniPlayerBottom = false
                    startAnimation = true
                }
                .onDisappear{
                    dismiss()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: startAnimation)

            }
        }
            
    }
    private func toggleEditMode(for index: Int) {
        if !isEditMode {
            isEditMode = true
            selectedIndices.insert(index)
        } else {
            toggleSelection(for: index)
        }
    }

    private func toggleSelection(for index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    func filteredUpNextSongs() -> [(song: Song, index: Int)] {
        return zip(audioManager.playlist.indices, audioManager.playlist)
            .filter { index, song in
                song.id != audioManager.currentSong?.id && audioManager.currentIndex < index
            }
            .map { index, song in (song: song, index: index) }
    }
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    private func playSongAt(index: Int) {
        guard let song = audioManager.playlist.indices.contains(index) ? audioManager.playlist[index] : nil else { return }
        audioManager.playSong(song, from: audioManager.playlist, isOnlySong: false, songIndex: index)
        audioManager.currentIndex = index
    }
    func deleteSelectedSongs() {
       
        let sortedIndices = selectedIndices.sorted(by: >)
        
        for index in sortedIndices {
            if audioManager.playlist.indices.contains(index) {
                audioManager.playlist.remove(at: index)
            }
        }
        
        isEditMode = false
        selectedIndices.removeAll()
    }
}




struct SongCoverViewQueueMain: View {
    var song: Song
    @EnvironmentObject var audioPlayer:AudioPlayerManager
    private var parsedComponents: [String] {
        song.title.components(separatedBy: " - ")
    }
    
    private var displayName: String {
        guard parsedComponents.count >= 2 else { return song.title }
        return parsedComponents[0] + " - " + parsedComponents[1]
    }
    
    var body: some View {
        VStack(spacing: 10) {
            AsyncCover (song:song ,size:120)
            
            VStack(spacing: 4) {
                Text(parsedComponents[0])
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
               
                    Text(parsedComponents[1])
                        .foregroundColor(.gray)
                        .frame(width: 300)
                        .lineLimit(1)
                        .truncationMode(.tail)
                
            }
        }.onChange(of: audioPlayer.currentTime) { newValue in
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
    }
}

struct SongRowView: View {
    var song: Song
    var index: Int
    @State private var animateCheckMark: Bool = false
    var isSelected: Bool
    var isEditMode: Bool
    @Binding var selectedIndices: Set<Int>
    @Binding var navPath: NavigationPath
    var onTap: () -> Void
    var onLongPress: () -> Void
    var onToggleSelect: () -> Void
    @EnvironmentObject var audioManager:AudioPlayerManager
    var body: some View {
        HStack {
            if isEditMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(isSelected ? .green : .gray)
                    .onTapGesture {
                        onToggleSelect()
                        animateCheckMark.toggle()
                       
                    }
                    .animation(.easeIn(duration:0.1),value:animateCheckMark)
            }
            
            SongCoverViewQueue(song: song, isEditMode: isEditMode)
            
            Spacer()
            
            if !isEditMode {
                Menu {
                    Button {
                        navPath.append(Route.addSingleSong(song))
                    } label: {
                        Label("Add to playlist", systemImage: "plus.circle")
                    }
                    Button {
                        navPath.append(Route.song(song))
                        
                    } label: {
                        Label("View Song", systemImage: "music.note")
                    }
                    Button(role: .destructive) {
                        if audioManager.playlist.indices.contains(index) {
                            selectedIndices.insert(index)
                            deleteSelectedSongs()
                            
                            
                        }
                    } label: {
                        Label("Remove From Queue", systemImage: "minus.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                onTap()
            }
        }
        
        .onLongPressGesture {
            onLongPress()
        }
    }
    private func deleteSelectedSongs() {
       
        let sortedIndices = selectedIndices.sorted(by: >)
        
        for index in sortedIndices {
            if audioManager.playlist.indices.contains(index) {
                audioManager.playlist.remove(at: index)
            }
        }
        
        
        selectedIndices.removeAll()
    }
    
    
    
    var selectedIndicesCount: Int { 0 }
}

struct SongCoverViewQueue: View {
    var song: Song
    var isEditMode: Bool
    
    private var parsedComponents: [String] {
        song.title.components(separatedBy: " - ")
    }
    
    private var displayName: String {
        guard parsedComponents.count >= 2 else { return song.title }
        return parsedComponents[0] + " - " + parsedComponents[1]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncCover (song:song, size:52)

    
            
            VStack(alignment: .leading, spacing: 4) {
                Text(parsedComponents[0])
                    .foregroundColor(.white)
                    .font(.subheadline)
                
               
                    Text(parsedComponents[1])
                        .foregroundColor(.gray)
                        .font(.caption)
                
            }
        }
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
            backgroundGradient
            
            VStack(spacing: 30) {
                playlistNameInput
                createPlaylistButton
                Spacer()
                cancelButton
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.03, green: 0.03, blue: 0.06)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var playlistNameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Playlist Name")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("My Awesome Playlist", text: $playlistName)
                .textFieldStyle(.plain)
                .padding()
                .focused($isTextFieldFocused)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .foregroundColor(.white)
                .autocorrectionDisabled()
        }
        .padding(.horizontal)
    }
    
    private var createPlaylistButton: some View {
        Button(action: createPlaylist) {
            Text("Create Playlist")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
        }
        .disabled(playlistName.isEmpty)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            navPath.removeLast(1)
            navPath.append(Route.queue)
        }
        .foregroundColor(.gray)
    }
    
    private func createPlaylist() {
        guard let currentUser = authManager.currentUser else { return }
        
        let newPlaylist = Playlist(name: playlistName, owner: currentUser)
        context.insert(newPlaylist)
        
        for (index, song) in songs.enumerated() {
            let entry = PlaylistSongs(order: index, playlist: newPlaylist, song: song)
            context.insert(entry)
            newPlaylist.entries.append(entry)
        }
        
        try? context.save()
        dismiss()
    }
}

