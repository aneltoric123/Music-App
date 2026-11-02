import SwiftUI
import Foundation
import SwiftData

struct SongView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    var song: Song
    @Binding var navPath: NavigationPath
    @State var showToast: Bool = false
    @State var toastMessage: String = ""
    var body: some View {
        if(audioManager.currentSong == song)  {
            SongViewPlaying(
                song: song,
                navPath: $navPath,
                onLike: {
                    toastMessage = likedSongs.contains(song)
                    ? "Added to Liked Songs"
                    : "Removed from Liked Songs"

                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    showToast = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showToast = false
                    }
                },
                showToast: $showToast,
                toastMessage: $toastMessage
            )
        }  else
        {
            SongViewViewing(
                    song: song,
                    navPath: $navPath,
                    onLike: {
                        toastMessage = likedSongs.contains(song)
                        ? "Added to Liked Songs"
                        : "Removed from Liked Songs"

                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        showToast = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showToast = false
                        }
                    },
                    showToast: $showToast,
                    toastMessage: $toastMessage
                )
        }
    }
    
}

struct SongViewPlaying:View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    var song: Song
    @Binding var navPath: NavigationPath
    let onLike: () -> Void
    var safeDuration: Double {
        if audioManager.totalDuration.isFinite &&
           !audioManager.totalDuration.isNaN &&
           audioManager.totalDuration > 0 {
            return audioManager.totalDuration
        }
        
        return 1
    }
    var parsedComponets: [Substring] { song.title.split(separator: " - ")}
    var displayName: String{
        parsedComponets[0] + " - "  + parsedComponets[1]
    }
   
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    var body: some View {
        ZStack{
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut, value: song.id)
            VStack(spacing: 25) {
                HStack {
                    Menu {
                        NavigationLink(destination: AddSongPlaylistView(song: song)) {
                            Label("Add to playlist", systemImage: "plus.circle")
                        }
                        Button {
                            likeSong()
                             onLike()
                        }
                        label:{
                            if(likedSongs.contains(song)){
                                Label("Unlike song", systemImage: "heart.fill")
                            }
                            else{
                                Label("Like song", systemImage: "heart")
                            }
                        }
                        Section("Artists"){
                            ForEach(song.artists){ artist in
                                NavigationLink(destination:NewArtist(artist: artist )){
                                    Label("\(artist.name)",systemImage:"person.text.rectangle.fill")
                                }
                            }
                        }
                        Section("Album"){
                            if(song.album != nil && song.album!.name != "Single"){
                                NavigationLink(destination: AlbumView(album: song.album!, isSearch: false)){
                                    Label("\(song.album!.name)",systemImage:"list.bullet.rectangle.fill")
                                }
                            }
                        }
                        if(!authManager.currentUser!.blockedSongs.contains(where: {$0.id == song.id})){
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
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }.compositingGroup()

                }
                
                if let url = resolveCoverURL(for: song){
                    AsyncCover(song: song, size: 200) .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                                        .scaleEffect(audioManager.isPlaying ? 1.03 : 1.0)
                                        .animation(.easeInOut (duration: 2))
                                } else {
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .foregroundColor(.gray)
                                }
                            
                  
                VStack(spacing: 8) {
                    Text(parsedComponets[0])
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(parsedComponets[1])
                            .font(.title2)
                            .foregroundStyle(.gray)
                    
                }
                Button {
                    likeSong()
                    onLike()
                } label: {
                    Image(systemName: likedSongs.contains(song) ? "heart.fill" : "heart")
                        .foregroundColor(.pink)
                        .font(.title)
                }
                VStack(spacing: 6) {
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
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                }
                .padding(.horizontal)
                HStack(spacing: 40) {
                    Spacer()
                    Button(action: {
                        audioManager.togglePlayPause()
                        audioManager.playPrevious()
                        if let previous = audioManager.currentSong {
                            if navPath.count > 1 {
                                navPath.removeLast(navPath.count - 1)
                            }
                            navPath.append(Route.song(previous))
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(audioManager.currentIndex != 0 ? .white : .gray.opacity(0.5))
                    }
                    .disabled(audioManager.currentIndex == 0)
                    Button {
                        audioManager.togglePlayPause()
                    } label: {
                        Image(systemName: audioManager.isPlaying && audioManager.currentSong == song ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .shadow(radius: 10)
                    }
                        .scaleEffect(audioManager.isPlaying ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: audioManager.isPlaying)
                    Button(action: {
                        audioManager.togglePlayPause()
                        audioManager.playNext()
                        if let next = audioManager.currentSong {
                            if navPath.count > 1 {
                                navPath.removeLast(navPath.count - 1)
                            }
                            navPath.append(Route.song(next))
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(audioManager.currentIndex + 1 != audioManager.playlist.count ? .white : .gray.opacity(0.5))
                    }
                    .disabled(audioManager.currentIndex + 1 == audioManager.playlist.count)
                    HStack{
                        
                        NavigationLink(destination: QueueView(navPath: $navPath)) {
                            Image(systemName: "music.pages.fill").font(.system(size: 50))
                                .shadow(radius: 10)
                        }
                    }
                    }
                    .padding(.horizontal)
                    .font(.title2)
                    .foregroundStyle(.white)
              
                VStack {
                    if showToast {
                        Text(toastMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                toastMessage == "Added to Liked Songs"
                                ? Color.green
                                : Color.red
                            )
                            .clipShape(Capsule())
                            .shadow(radius: 10)
                            .padding(.bottom, 30)
                            .transition(
                                .move(edge: .bottom)
                                .combined(with: .opacity)
                            )
                            .zIndex(999)
                    }
                }.animation(.spring(duration: 0.4), value: showToast)
               
            }
            
            .shadow(color: .blue.opacity(0.6), radius: 30)
        }.transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.3), value: song.id).onAppear {
                audioManager.isShowingMiniPlayer = false
                audioManager.isShowingMiniPlayerBottom = false
                
            }
            .onChange(of: audioManager.currentTime) { newValue in
                if audioManager.totalDuration.isFinite && !audioManager.totalDuration.isNaN {
                    if newValue >= audioManager.totalDuration - 0.5 {
                        if audioManager.currentIndex < audioManager.playlist.count - 1 {
                            audioManager.playNext()
                        } else {
                            audioManager.stopQueue()
                        }
                    }
                }
            }
           
            
            
        
        
    }

    @MainActor func likeSong(){
        
        if(likedSongs.contains(song)){
            likedSongsPlaylist.entries.removeAll(where: {$0.song.title == song.title})
            try? context.save()
        }
        else{
            likedSongsPlaylist.entries.append(PlaylistSongs(order:likedSongsPlaylist.entries.count,playlist: likedSongsPlaylist, song: song))
            try? context.save()
            
        }
    }

    @MainActor func hideSong(isBlocked:Bool) {
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
            authManager.currentUser!.blockedSongs.append(song)
        }
        else{
            authManager.currentUser!.blockedSongs.removeAll(){
                $0.id == song.id
            }
        }
        try? context.save()
    }

    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func formatArtists(_ artists: [Artist]) -> String {
        guard !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }
    }

struct SongViewViewing:View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    var song: Song
    @Binding var navPath: NavigationPath
    let onLike:() -> Void
    var parsedComponets: [Substring] { song.title.split(separator: " - ")}
    var displayName: String{
        parsedComponets[0] + " - "  + parsedComponets[1]
    }
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut, value: song.id)
            
            VStack(spacing: 25) {
                
                
                HStack {
                    Menu {
                        NavigationLink(destination: AddSongPlaylistView(song: song)) {
                            Label("Add to playlist", systemImage: "plus.circle")
                        }
                        
                        Button {
                            likeSong()
                             onLike()
                        }
                        label:{
                            if(likedSongs.contains(song)){ Label("Unlike song", systemImage: "heart.fill")
                            }
                            else{
                                Label("Like song", systemImage: "heart")
                            }
                        }
                        Section("Artists"){
                            ForEach(song.artists){ artist in
                                NavigationLink(destination:NewArtist(artist: artist)){
                                    Label("\(artist.name)",systemImage:"person.text.rectangle.fill")
                                }
                            }
                        }
                        Section("Album"){
                            if(song.album != nil && song.album!.name != "Single"){
                                NavigationLink(destination:AlbumView(album: song.album!, isSearch: false)){
                                    Label("\(song.album!.name)",systemImage:"list.bullet.rectangle.fill")
                                }
                            }
                        }
                        
                        if(!authManager.currentUser!.blockedSongs.contains(where: {$0.id == song.id})){
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
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }.compositingGroup()

                }
              
                
                
                
                if let url = resolveCoverURL(for: song){
                    AsyncCover(song: song, size: 200)
                                   
                                } else {
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .foregroundColor(.gray)
                                }
                            
                
                
                VStack(spacing: 10) {
                    Text(parsedComponets[0])
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                   
                        Text(parsedComponets[1])
                            .font(.title2)
                            .foregroundStyle(.gray)
                    
                    
                    Button{
                        likeSong()
                        onLike()
                       
                    } label :{
                      Image(systemName: likedSongs.contains(song) ? "heart.fill" : "heart")
                            .foregroundColor(.pink)
                            .font(.title)
                    }
                    
                    
                    Button {
                        audioManager.playSong(song, from: [song], isOnlySong: true)
                    } label: {
                        Image(systemName: audioManager.isPlaying && audioManager.currentSong == song ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                            .padding()
                    }
                   
                }
                VStack {
                    if showToast {
                        Text(toastMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(toastMessage == "Added to Liked Songs" ? .green  : .red)
                            .clipShape(Capsule())
                            .shadow(radius: 10)
                            .padding(.bottom, 120)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
                .onAppear{
                    if audioManager.currentSong != song{
                        audioManager.isShowingMiniPlayerBottom = true
                        audioManager.isShowingMiniPlayer = false
                    }
                }.onChange(of: audioManager.currentTime) { newValue in
                    if audioManager.totalDuration.isFinite && !audioManager.totalDuration.isNaN {
                        if newValue >= audioManager.totalDuration - 0.5 {
                            if audioManager.currentIndex < audioManager.playlist.count - 1 {
                                audioManager.playNext()
                            } else {
                                audioManager.stopQueue()
                            }
                        }
                    }
                }
            
        } .animation(.spring(duration: 0.4), value: showToast)
    }

    @MainActor func likeSong(){
        
        if(likedSongs.contains(song)){
            likedSongsPlaylist.entries.removeAll(where: {$0.song.id_song == song.id_song})
            try? context.save()
        }
        else{
            likedSongsPlaylist.entries.append(PlaylistSongs(order:likedSongsPlaylist.entries.count ,playlist: likedSongsPlaylist, song: song))
            try? context.save()
            
        }
    }

    @MainActor func hideSong(isBlocked:Bool) {
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
            authManager.currentUser!.blockedSongs.append(song)
        }
        else{
            authManager.currentUser!.blockedSongs.removeAll(){
                $0.id == song.id
            }
        }
        try? context.save()
    }
    func formatArtists(_ artists: [Artist]) -> String {
        guard !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }
    }


