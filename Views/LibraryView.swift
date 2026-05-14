import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @Query private var playlists: [Playlist]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                header

                TypeBarView()
                    .padding(.horizontal)
            }
            .padding(.top, 20)
        }
        .onAppear{
            if(audioManager.isShowingMiniPlayer == false){
                audioManager.isShowingMiniPlayer.toggle()
            }
        }
        .background(background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            Text("Your Library")
                .font(.largeTitle)
                .bold()

            Spacer()

            HStack(spacing: 16) {
                NavigationLink(destination: LibrarySearchView()) {
                    Image(systemName: "magnifyingglass")
                }

                NavigationLink(destination: CreatePlaylistView()) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .font(.title2)
        }
        .padding(.horizontal)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct TypeBarView: View {
    @State private var selectedType: String = "All"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                typeButton("All")
                typeButton("Playlists")
                typeButton("Artists")
            }

            TypeView(selectedType: selectedType)
        }
    }

    private func typeButton(_ type: String) -> some View {
        Button {
            withTransaction(Transaction(animation: nil)) {
                selectedType = type
            }
        } label: {
            Text(type)
                .font(.title3)
                .frame(height: 40)
                .frame(minWidth: 100)
                .background(
                    Group {
                        if selectedType == type {
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .foregroundColor(selectedType == type ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedType == type ? .green : .gray, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
;

struct TypeView: View {
    var selectedType: String

    @EnvironmentObject var authManager: AuthManager

    @State private var selectedSort: String = "name"
    @State private var typeSort: String = "up"

    @State private var sortedPlaylists: [Playlist] = []
    @State private var sortedArtists: [Artist] = []

    var body: some View {
        VStack(spacing: 16) {

            SortView(selectedSort: $selectedSort, typeSort: $typeSort)

            content
        }
        .onAppear(perform: sortData)
        .onChange(of: selectedSort) { _ in sortData() }
        .onChange(of: typeSort) { _ in sortData() }
    }

    private var playlists: [Playlist] {
        authManager.currentUser?.playlists ?? []
    }

    private var artists: [Artist] {
        authManager.currentUser?.followedArtists ?? []
    }

    private func sortData() {
        var p = playlists
        if selectedSort == "name" {
            p.sort { $0.name < $1.name }
        } else {
            p.sort { $0.entries.count < $1.entries.count }
        }
        if typeSort == "down" { p.reverse() }
        sortedPlaylists = p

        var a = artists
        if selectedSort == "name" {
            a.sort { $0.name < $1.name }
        } else {
            a.sort { $0.songs.count < $1.songs.count }
        }
        if typeSort == "down" { a.reverse() }
        sortedArtists = a
    }

    @ViewBuilder
    private var content: some View {
        switch selectedType {

        case "Artists":
            VStack(spacing: 10) {
                ForEach(sortedArtists, id: \.id) { artist in
                    NavigationLink(destination: ArtistView(artist: artist, isSearch: false)) {
                        ArtistSearchLibraryView(artist: artist)
                    }.buttonStyle(PlainButtonStyle()).contentShape(Rectangle()) .navigationLinkIndicatorVisibility(.hidden)
                }
            }

        case "Playlists":
            playlistGrid(sortedPlaylists)

        default:
            VStack(spacing: 20) {
                playlistGrid(sortedPlaylists)

                VStack {
                    ForEach(sortedArtists, id: \.id) { artist in
                        NavigationLink(destination: ArtistView(artist: artist, isSearch: false)) {
                            ArtistSearchLibraryView(artist: artist)
                        }.buttonStyle(PlainButtonStyle()).contentShape(Rectangle())
                            .navigationLinkIndicatorVisibility(.hidden)
                    }
                }
            }
        }
    }

    private func playlistGrid(_ data: [Playlist]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 20) {
            ForEach(data, id: \.id) { playlist in
                NavigationLink(destination: PlaylistView(playlist: playlist)) {
                    PlaylistCardView(playlist: playlist)
                }.buttonStyle(PlainButtonStyle()).contentShape(Rectangle())
                    .navigationLinkIndicatorVisibility(.hidden)
            }
        }
    }
}

struct PlaylistCardView: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            ZStack {
                if playlist.name == "Liked Songs" {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.purple, .pink],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))

                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)

                } else if playlist.entries.count >= 1 {
                    SongCoversGrid(songs: playlist.entries.map(\.song))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.gray, .black],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                }
            }
            .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(playlist.entries.count) songs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SongCoversGrid: View {
    let songs: [Song]

    var body: some View {
        let size: CGFloat = 75

        if songs.count < 4, let first = songs.first {
            SongCoverImage(song: first, size: 150)
        } else if songs.count >= 4 {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    SongCoverImage(song: songs[0], size: size)
                    SongCoverImage(song: songs[1], size: size)
                }
                HStack(spacing: 0) {
                    SongCoverImage(song: songs[2], size: size)
                    SongCoverImage(song: songs[3], size: size)
                }
            }
        }
    }
}
struct SongCoverImage: View {
    let song: Song
    let size: CGFloat
    var body: some View {
        Group {
            Image(song.coverpath) .resizable() .scaledToFill() } .frame(width: size, height: size) .clipped()
    }
}
struct CreatePlaylistView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth:AuthManager
    var user: User{ auth.currentUser! }
    @State private var playlistName = ""
    @FocusState private var isTextFieldFocused: Bool
    var body: some View {
        ZStack {
            LinearGradient( gradient: Gradient(colors: [ Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.03, green: 0.03, blue: 0.06) ]), startPoint: .top, endPoint: .bottom )
                .ignoresSafeArea()
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Playlist Name") .font(.subheadline) .foregroundColor(.gray)
                    TextField("My Awesome Playlist", text: $playlistName).focused($isTextFieldFocused).textFieldStyle(.plain) .padding().background( RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)) ).overlay( RoundedRectangle(cornerRadius: 10) .stroke(Color.white.opacity(0.2), lineWidth: 1) ) .foregroundColor(.white) .autocorrectionDisabled() } .padding(.horizontal)
                Button(action: createPlaylist) {
                    Text("Create Playlist") .font(.headline) .foregroundColor(.white) .frame(maxWidth: .infinity) .padding() .background( LinearGradient( gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing ) ) .cornerRadius(12) }
                .disabled(playlistName.isEmpty).padding(.horizontal).padding(.bottom, 20)
                Spacer()
            }.onAppear { isTextFieldFocused = true }
        } .navigationTitle("New Playlist").navigationBarTitleDisplayMode(.inline).toolbar
        { ToolbarItem(placement: .navigationBarLeading)
            { Button("Cancel") { dismiss()
            }.foregroundColor(.white)
            }
        }
    }
    private func createPlaylist() {
        let newPlaylist = Playlist(name: playlistName,owner: user)
        context.insert(newPlaylist)
        do {
            try context.save()
            dismiss() }
        catch {
            print("Failed to create playlist: \(error)")
        }
    }
}
struct SortView: View {
    @Binding var selectedSort: String
    @Binding var typeSort: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Sort by")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {

                sortButton("A-Z", value: "name")
                sortButton("No. of songs", value: "noSong")

                Spacer()

                arrowButton(system: "arrowtriangle.up.fill", value: "up")
                arrowButton(system: "arrowtriangle.down.fill", value: "down")
            }
        }
    }

    private func sortButton(_ title: String, value: String) -> some View {
        Button {
            selectedSort = value
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(
                    Group {
                        if selectedSort == value {
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .foregroundColor(selectedSort == value ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func arrowButton(system: String, value: String) -> some View {
        Button {
            typeSort = value
        } label: {
            Image(systemName: typeSort == value ? system : system.replacingOccurrences(of: ".fill", with: ""))
                .font(.system(size: 14, weight: .bold))
                .frame(width: 32, height: 32)
                .background(
                    Group {
                        if typeSort == value {
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .foregroundColor(typeSort == value ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
