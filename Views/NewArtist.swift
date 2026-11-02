import SwiftUI
import Foundation
import SwiftData


struct AlbumEntry: Codable,Identifiable {
    var id: Int { id_album }
    let id_album: Int
    let name: String
    let artists_ids: [Int]
    let songs:  [SongEntry]
}

struct SongEntry: Codable,Identifiable {
    var id: Int { id_song }
    let id_song: Int
    let title: String
    let filepath: String
    let album_id: Int
    let genre_id: Int
    let artist_ids: [Int]
}


private enum ArtistTheme {
    static let accent      = Color.cyan
    static let bgTop       = Color(red: 0.08, green: 0.65, blue: 0.22)
    static let bgMid       = Color(red: 0.04, green: 0.35, blue: 0.12)
    static let bgBottom    = Color.black
    static let cardBG      = Color.white.opacity(0.07)
    static let cardStroke  = Color.white.opacity(0.10)
    static let corner: CGFloat = 16
    static let sectionGap: CGFloat = 28
    static let itemGap:   CGFloat = 10
}


struct NewArtist: View {
    var artist: Artist
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var context

    @State var selectedType: String = "All"
    @State private var featuredSong: Song?
    @State private var allRelatedAlbums: [AlbumEntry] = []
    @State private var featureSongs: [SongEntry] = []
    @State private var singleSongs: [SongEntry] = []
    @State private var appeared = false

    var filteredAlbums: [AlbumEntry] { allRelatedAlbums }

   
    var displayName: String {
        guard let song = featuredSong else { return "" }
        let parts = song.title.split(separator: " - ")
        guard parts.count >= 2 else { return song.title }
        return "\(parts[0]) - \(parts[1])"
    }

    var user: User { authManager.currentUser! }
    var likedSongsPlaylist: Playlist { authManager.likedSongsPlaylist! }
    var likedSongs: [Song] { likedSongsPlaylist.songs }
    var blockedSongs: [Song] { authManager.currentUser!.blockedSongs }
    var blockedArtists: [Artist] { authManager.currentUser!.blockedArtists }

    
    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                    filterTabs
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    contentSection
                        .padding(.horizontal, 20)
                        .padding(.top, ArtistTheme.sectionGap)
                        .padding(.bottom, audioManager.currentSong != nil ? 110 : 20)
                }
            }
        }
        .onAppear {
            audioManager.isShowingMiniPlayer = false
            audioManager.isShowingMiniPlayerBottom = true
            loadArtistData()
            if featuredSong == nil { pickFeaturedSong() }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onChange(of: artist.id) { _ in
            featuredSong = nil
            appeared = false
            loadArtistData()
            pickFeaturedSong()
            print(featuredSong)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // ── Background ──────────────────────────────────────
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [ArtistTheme.bgTop, ArtistTheme.bgMid, ArtistTheme.bgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    
    private var heroHeader: some View {
        HStack(alignment: .center, spacing: 20) {
            
            if featuredSong != nil{
                AsyncCover(song:featuredSong!,size:52)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(artist.name)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)

                
                HStack(spacing: 14) {
                    statBadge(icon: "music.note", label: "\(singleSongs.count)")
                    statBadge(icon: "mic.fill", label: "\(featureSongs.count)")
                    statBadge(icon: "square.stack", label: "\(allRelatedAlbums.count)")
                }
                .padding(.top, 4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : 16)
        }
    }

    private func statBadge(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(ArtistTheme.accent)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }


    private var filterTabs: some View {
        HStack(spacing: 10) {
            typeButton("All")
            typeButton("Singles")
            typeButton("Features")
            typeButton("Albums")
        }
    }

    private func typeButton(_ type: String) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                selectedType = type
            }
        } label: {
            Text(type)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background {
                    if selectedType == type {
                        Capsule()
                            .fill(LinearGradient(
                                colors: [ArtistTheme.accent, ArtistTheme.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: ArtistTheme.accent.opacity(0.35), radius: 8, y: 3)
                    } else {
                        Capsule().fill(Color.white.opacity(0.06))
                    }
                }
                .foregroundStyle(selectedType == type ? .white : .white.opacity(0.65))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            selectedType == type ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    
    @ViewBuilder
    private var contentSection: some View {
        switch selectedType {
        case "All":
            AllContent(
                artist: artist,
                singleSongs: singleSongs,
                featureSongs: featureSongs,
                albums: allRelatedAlbums
            )
        case "Singles":
            SinglesContent(artist: artist, songs: singleSongs)
        case "Features":
            FeaturesContent(artist: artist, songs: featureSongs)
        case "Albums":
            AlbumsContent(artist: artist, albums: allRelatedAlbums)
        default:
            EmptyView()
        }
    }

   
    
    func loadArtistData() {
            let key = String(artist.id)

            if let url = Bundle.main.url(forResource: "album_dictionary", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([String: [AlbumEntry]].self, from: data) {
                allRelatedAlbums = decoded[key] ?? []
            }

            if let url = Bundle.main.url(forResource: "main_dictionary", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([String: [SongEntry]].self, from: data) {
                singleSongs = decoded[key] ?? []
            }

            if let url = Bundle.main.url(forResource: "feature_dictionary", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([String: [SongEntry]].self, from: data) {
                featureSongs = decoded[key] ?? []
            }
        }

    


    private func pickFeaturedSong() {
        let pool = singleSongs.isEmpty ? featureSongs : singleSongs
        if let random = pool.randomElement() {
            featuredSong = Song(id: random.id, title: random.title, filepath: random.filepath)
        }
    }
}


private struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.footnote.weight(.bold))
                .tracking(1.2)
                .foregroundColor(ArtistTheme.accent)

            Text("\(count)")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white.opacity(0.4))

            Spacer()
        }
        .padding(.bottom, 12)
    }
}


private struct AllContent: View {
    var artist: Artist
    var singleSongs: [SongEntry]
    var featureSongs: [SongEntry]
    var albums: [AlbumEntry]

    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: ArtistTheme.sectionGap) {

            if !singleSongs.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "Singles", count: singleSongs.count)
                    horizontalSongRow(songs: singleSongs)
                }
            }

            if !featureSongs.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "Features", count: featureSongs.count)
                    horizontalSongRow(songs: featureSongs)
                }
            }

            if !albums.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "Albums", count: albums.count)
                    horizontalAlbumRow(albums: albums)
                }
            }
        }
    }

    private func horizontalSongRow(songs: [SongEntry]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ArtistTheme.itemGap) {
                ForEach(songs) { entry in
                    let song = Song(id: entry.id, title: entry.title, filepath: entry.filepath)
                    SongCard(song: song, artist: artist)
                        .onTapGesture {
                            audioManager.playSong(song, from: [song], artist: artist, isOnlySong: true)
                        }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func horizontalAlbumRow(albums: [AlbumEntry]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ArtistTheme.itemGap) {
                ForEach(albums) {entry in
                    let album = Album(id: entry.id, name: entry.name)
                    NavigationLink(destination: NewAlbumView(album: album, isSearch: false,songs:entry.songs)) {
                        AlbumTile(entry: entry, album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}


private struct SinglesContent: View {
    var artist: Artist
    var songs: [SongEntry]

    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Singles", count: songs.count)

            ForEach(songs) { entry in
                let song = Song(id: entry.id, title: entry.title, filepath: entry.filepath)
                SongCard(song: song, artist: artist)
                    .onTapGesture {
                        audioManager.playSong(song, from: [song], artist: artist, isOnlySong: true)
                    }
            }
        }
    }
}


private struct FeaturesContent: View {
    var artist: Artist
    var songs: [SongEntry]

    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Features", count: songs.count)

            ForEach(songs) { entry in
                let song = Song(id: entry.id, title: entry.title, filepath: entry.filepath)
                SongCard(song: song, artist: artist)
                    .onTapGesture {
                        audioManager.playSong(song, from: [song], artist: artist, isOnlySong: true)
                    }
            }
        }
    }
}


private struct AlbumsContent: View {
    var artist: Artist
    var albums: [AlbumEntry]

    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Albums", count: albums.count)

            ForEach(albums) { entry in
                let album = Album(id: entry.id, name: entry.name)
                NavigationLink(destination: NewAlbumView(album: album, isSearch: false,songs:entry.songs)) {
                    AlbumTileFull(entry: entry, album: album)
                }
                .buttonStyle(.plain)
            }
        }
    }
}


private struct SongCard: View {
    let song: Song
    let artist: Artist

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @Environment(\.modelContext) private var context

    var user: User { authManager.currentUser! }
    var likedSongsPlaylist: Playlist { authManager.likedSongsPlaylist! }
    var likedSongs: [Song] { authManager.likedSongsPlaylist!.songs }

    private var isBlocked: Bool {
        user.blockedSongs.contains { $0.id == song.id } ||
        song.artists.contains { a in
            user.blockedArtists.contains { $0.id == a.id }
        }
    }

    var parsedComponents: [Substring] {
        song.title.split(separator: " - ")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncCover(song:song,size:52)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(parsedComponents[0]))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundColor(.white)

                if parsedComponents.count > 1 {
                    Text(String(parsedComponents[1]))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

           
            Button {
                toggleLike()
            } label: {
                Image(systemName: likedSongs.contains(song) ? "heart.fill" : "heart")
                    .font(.footnote)
                    .foregroundColor(likedSongs.contains(song) ? .pink : .white.opacity(0.35))
            }
            .buttonStyle(.plain)

            
            Menu {
                NavigationLink(destination: AddSongPlaylistView(song: song)) {
                    Label("Add to playlist", systemImage: "plus.circle")
                }
                Button(isBlocked ? "Unblock" : "Block", systemImage: "play.slash.fill") {
                    toggleBlock()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.35))
            }.compositingGroup()
            
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: ArtistTheme.corner)
                .fill(ArtistTheme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: ArtistTheme.corner)
                        .strokeBorder(ArtistTheme.cardStroke, lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .onTapGesture {
            if !isBlocked {
                audioPlayer.playSong(song, from: [song], artist: artist, isOnlySong: true)
            }
        }
    }

    @MainActor private func toggleLike() {
        if likedSongs.contains(song) {
            likedSongsPlaylist.entries.removeAll { $0.song.id == song.id }
        } else {
            likedSongsPlaylist.entries.append(
                PlaylistSongs(order: likedSongsPlaylist.entries.count + 1,
                              playlist: likedSongsPlaylist,
                              song: song)
            )
        }
        try? context.save()
    }

    @MainActor private func toggleBlock() {
        if !user.blockedSongs.contains(where: { $0.id == song.id }) {
            likedSongsPlaylist.entries.removeAll { $0.song.id == song.id }
            let descriptor = FetchDescriptor<Playlist>()
            if let playlists = try? context.fetch(descriptor) {
                for pl in playlists {
                    pl.entries.removeAll { $0.song.id == song.id }
                }
            }
            audioPlayer.playlist.removeAll { $0.id == song.id }
            if audioPlayer.currentSong?.id == song.id { audioPlayer.playNext() }
            user.blockedSongs.append(song)
        } else {
            user.blockedSongs.removeAll { $0.id == song.id }
        }
        try? context.save()
    }
}


private struct AlbumTile: View {
    let entry: AlbumEntry
    let album: Album
    private var firstSongs:Song {
        entry.songs.first.map{ _ in Song(id: entry.songs.first!.id, title: entry.songs.first!.title, filepath: entry.songs.first!.filepath) }!
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Artwork placeholder or image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                if entry.songs.first != nil{
                    AsyncCover (song:firstSongs ,size:140)
                }
                else {
                    Image(systemName: "opticaldisc.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.25))
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)

            Text(entry.name)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 140, alignment: .leading)
        }
        .frame(width: 140)
    }
}


private struct AlbumTileFull: View {
    let entry: AlbumEntry
    let album: Album
    private var firstSongs:Song {
        entry.songs.first.map{ _ in Song(id: entry.songs.first!.id, title: entry.songs.first!.title, filepath: entry.songs.first!.filepath) }!
    }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                if  firstSongs != nil{
                    AsyncCover(song: firstSongs, size: 72)
                }
                    else {
                    Image(systemName: "opticaldisc.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.25))
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if !album.artists.isEmpty {
                    Text(album.artists.map { $0.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: ArtistTheme.corner)
                .fill(ArtistTheme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: ArtistTheme.corner)
                        .strokeBorder(ArtistTheme.cardStroke, lineWidth: 1)
                )
        }
    }
}
