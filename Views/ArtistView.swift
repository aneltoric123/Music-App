import SwiftData
import SwiftUI
import UIKit

struct ArtistView: View {
    var artist: Artist
    var isSearch: Bool
  
    @EnvironmentObject var authManager: AuthManager
    var user: User{
        authManager.currentUser!
    }
    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.modelContext) private var context
    @Query private var searches: [ArtistSearchHistory]
    @Query private var allRelatedSongs: [Song]
    @State private var showToast:Bool = false
    @State private var toastMessage:String = ""
    @State private var didSave:Bool = false
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    
    
    
    init(artist: Artist, isSearch: Bool) {
        self.artist = artist
        self.isSearch = isSearch
        
        let targetId = artist.id
        self._allRelatedSongs = Query(
            filter: #Predicate<Song> {
                $0.artists.contains(where: { $0.id == targetId })
            },
            sort: \Song.title,
            order: .reverse
        )
    }
    
    var body: some View {
    
        ZStack {
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
            }
                ScrollView {
                    VStack(spacing: 0) {
                        heroSection
                        songsList
                        Spacer()
                    }
                }
            
            VStack {
                Spacer()
                
                if showToast {
                    Text(toastMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(toastMessage == "Added to Liked Songs" ? .green  : .red)
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }.onAppear{
            audioManager.isShowingMiniPlayer = false
            audioManager.isShowingMiniPlayerBottom = true
        }
        .animation(.spring(duration: 0.4), value: showToast)
    }
    
    
    @MainActor
    private func performSearchArtist() {
        print("Saved artist:", artist.name)
        
        if let exists = searches.first(where: { $0.artist.id == artist.id }) {
            context.delete(exists)
        }
        
        context.insert(ArtistSearchHistory(artist: artist,user: authManager.currentUser!))
        
        do {
            try context.save()
        } catch {
            print("Failed to save \(error)")
        }
    }
    func unblockArtist(){
        user.blockedArtists.removeAll(){
            artist.id == $0.id
        }
       try? context.save()
   }
    
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 10){
                    
                    let imageName = allRelatedSongs.first?.coverpath ?? "person.circle.fill"
                    
                    Image(imageName)
                        .resizable()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(radius: 10)
                    
                    Text(artist.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .frame(height: 240)
            
            if authManager.currentUser!.blockedArtists.contains(where: { $0.id == artist.id }) {
                HStack(spacing: 12) {
                    
                    Image(systemName: "slash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Artist Blocked")
                            .font(.headline)
                        
                        Text("You won't see or play songs from this artist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        unblockArtist()
                    } label: {
                        Text("Unblock")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color.red.opacity(0.08))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                statView(count: mainSongs.count, label: "Main Tracks")
                statView(count: featuredSongs.count, label: "Features")
                statView(count: blockedSongs.count, label: "Blocked")
                
                
                
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }.onAppear{
            audioManager.isShowingMiniPlayer = false
            audioManager.isShowingMiniPlayerBottom = true
        }
    }
    
    
    private var songsList: some View {
        VStack(spacing: 0) {
            
            if !mainSongs.isEmpty {
                sectionHeader(title: "Main Songs", count: mainSongs.count)
                songsGrid(songs: mainSongs,artist: artist)
            }
            
            if !featuredSongs.isEmpty {
                sectionHeader(title: "Featured On", count: featuredSongs.count)
                songsGrid(songs: featuredSongs,artist: artist)
            }
            if(!blockedSongs.isEmpty){
                sectionHeader(title: "Blocked", count: blockedSongs.count)
                songsGrid(songs: blockedSongs, artist: artist)
            }
        }
        .padding(.top, 16)
    }
    
    
    private func statView(count: Int, label: String) -> some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text("\(count) songs")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func songsGrid(songs: [Song],artist:Artist) -> some View {
        LazyVStack(spacing:12) {
            ForEach(songs,id:\.id) { song in
                Button{
                    if !(user.blockedSongs.contains(where: {$0.id == song.id}) ||
                         song.artists.contains{ artist in  user.blockedArtists.contains{ blockedArtist in  blockedArtist.id == artist.id }
                    }) {
                        audioManager.playSong(song, from: [song], artist: artist, isOnlySong: true)
                    }
                }label: {
                    SongCardView(song: song,artist:artist,onLike: {
                        toastMessage  = (!(likedSongs.contains(song))) ? "Removed from Liked Songs" : "Added to Liked Songs"
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            
                        showToast = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showToast = false
                        }
                    })
                }
                
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    private var visibleSongs: [Song] {
       allRelatedSongs.filter { song in
                !isSongBlocked(song)
        }
    }


    private var mainSongs: [Song] {
        visibleSongs.filter { $0.artists.first?.id == artist.id }
    }

    private var featuredSongs: [Song] {
        visibleSongs.filter { $0.artists.first?.id != artist.id }
    }
    private var blockedSongs: [Song] {
        allRelatedSongs.filter(isSongBlocked)
            }
        
   
    private func isSongBlocked(_ song: Song) -> Bool {
        let songBlocked = user.blockedSongs.contains { $0.id == song.id }

        let artistBlocked = song.artists.contains { artist in
            user.blockedArtists.contains { $0.id == artist.id }
        }

        return songBlocked || artistBlocked
    }
}



struct SongCardView: View {
    let song: Song
    let artist: Artist
    let onLike: () -> Void

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @Environment(\.modelContext) private var context

    var user: User { authManager.currentUser! }
    var likedSongsPlaylist: Playlist {
        authManager.likedSongsPlaylist!
    }
    var likedSongs: [Song] { authManager.likedSongsPlaylist!.songs }

    private var isBlocked: Bool {
        user.blockedSongs.contains { $0.id == song.id } ||
        song.artists.contains { a in
            user.blockedArtists.contains { $0.id == a.id }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            
            
            Image(song.coverpath)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .opacity(isBlocked ? 0.3 : 1)
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(formatArtists(song.artists))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                likeSong()
                onLike()
            } label: {
                Image(systemName: likedSongs.contains(song) ? "heart.fill" : "heart")
                    .foregroundColor(.pink)
            }
            Button{
            }
            label:{
                Menu {
                    NavigationLink(destination: AddSongPlaylistView(song: song)) {
                        Label("Add to playlist", systemImage: "plus.circle")
                    }
                    
                    Button(isBlocked ? "Unblock" : "Block", systemImage: "play.slash.fill") {
                        hideSong(isBlocked: isBlocked)
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }.compositingGroup()    

                
            }
        }.contentShape(Rectangle())
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .onTapGesture {
            if !isBlocked {
                audioPlayer.playSong(song, from: [song], artist: artist, isOnlySong: true)
            }
        }
       
    }

    @MainActor func hideSong(isBlocked:Bool){
        if(!isBlocked){
            likedSongsPlaylist.entries.removeAll { $0.song.id == song.id }
                   let descriptor = FetchDescriptor<Playlist>()
                   if let playlists = try? context.fetch(descriptor) {
                       for playlist in playlists {
                           playlist.entries.removeAll { $0.song.id == song.id }
                       }
                   }
            audioPlayer.playlist.removeAll { $0.id == song.id }
                   if audioPlayer.currentSong?.id == song.id {
                       audioPlayer.playNext()
                   }
            user.blockedSongs.append(song)
        }
        else{
            user.blockedSongs.removeAll{$0.id == song.id}
        }
        
        try? context.save()
    }
    @MainActor func likeSong(){
        
        if(likedSongs.contains(song)){
            likedSongsPlaylist.entries.removeAll(where: {$0.song.id == song.id})
            try? context.save()
        }
        else{
            likedSongsPlaylist.entries.append(PlaylistSongs(order:likedSongsPlaylist.entries.count + 1,playlist: likedSongsPlaylist, song: song))
            try? context.save()
            
        }
    }
    private func isSongBlocked(_ song: Song) -> Bool {
        let songBlocked = user.blockedSongs.contains { $0.id == song.id }

        let artistBlocked = song.artists.contains { artist in
            user.blockedArtists.contains { $0.id == artist.id }
        }

        return songBlocked || artistBlocked
    }
    

    private func formatArtists(_ artists: [Artist]) -> String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}
