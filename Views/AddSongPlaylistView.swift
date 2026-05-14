import SwiftUI
import SwiftData


struct AddSongPlaylistView: View {
    let song: Song
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager:AuthManager
    @EnvironmentObject var audioManager:AudioPlayerManager
    @Query private var allplaylists: [Playlist]
    var playlists:[Playlist]{
       allplaylists.filter{
            $0.owner == authManager.currentUser
        }
    }
    @State private var selectedPlaylists: Set<UUID> = []

    var body: some View {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.12),
                                                Color(red: 0.03, green: 0.03, blue: 0.06)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SongHeaderView(song: song)

                        Text("Your Playlists")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(playlists) { playlist in
                                PlaylistSelectionRow(
                                    playlist: playlist,
                                    isSelected: selectedPlaylists.contains(playlist.id_playlist)
                                )
                                .onTapGesture {
                                    toggleSongInPlaylist(playlist)
                                }
                            }
                        }
                        .padding(.horizontal)

                        NavigationLink {
                            CreatePlaylistWithSongView(song: song)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Create New Playlist")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
            .onAppear {
                selectedPlaylists = Set(playlists.compactMap { playlist in
                    playlist.entries.contains {
                        $0.song.id == song.id
                    } ? playlist.id_playlist : nil
                })
                audioManager.isShowingMiniPlayer = false
            }
        
    }

    private func toggleSongInPlaylist(_ playlist: Playlist) {

        if let existingIndex = playlist.entries.firstIndex(
            where: { $0.song.id == song.id }
        ) {

            let existing = playlist.entries[existingIndex]

            playlist.entries.remove(at: existingIndex)

            context.delete(existing)

            selectedPlaylists.remove(playlist.id_playlist)

        } else {

            let link = PlaylistSongs(
                playlistSongs_id: UUID(),
                order: playlist.entries.count + 1,
                playlist: playlist,
                song: song
            )
            playlist.entries.append(link)

            selectedPlaylists.insert(playlist.id_playlist)
        }

        do {
            try context.save()
        } catch {
            print(error)
        }
    }
}

struct SongHeaderView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 16) {
            Image(song.coverpath)
                    .resizable()
                    .scaledToFill()
            
        }
        .frame(width: 60, height: 60)
        .cornerRadius(8)
        .clipped()

        VStack(alignment: .leading, spacing: 4) {
            Text(song.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            Text(song.artists.formatted())
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}

struct PlaylistSelectionRow: View {
    let playlist: Playlist
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            if playlist.name == "Liked Songs" {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.purple, .pink]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    )
                    .frame(width: 50, height: 50)
            } else {
                PlaylistCoverViewAdd(playlist: playlist)
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.subheadline)
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
        let songs = Array(
            playlist.entries
                .sorted { $0.timeAdded > $1.timeAdded }
                .prefix(4)
                .map(\.song)
        )

        let size: CGFloat = 25

        VStack(spacing: 0) {

            if songs.isEmpty {

                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.gray, .black],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))

            } else if songs.count > 3 {

                HStack(spacing: 0) {
                    ForEach(Array(songs.prefix(2))) { song in
                        SongCoverImageAdd(song: song, size: size)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(Array(songs.suffix(2))) { song in
                        SongCoverImageAdd(song: song, size: size)
                    }
                }

            } else if let lastSong = songs.last {

                SongCoverImageAdd(song: lastSong, size: 50)
            }
        }
        .cornerRadius(4)
        .clipped()
    }
}

struct SongCoverImageAdd: View {
    let song: Song
    let size: CGFloat

    var body: some View {
            Image(song.coverpath)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()
    }
}

struct CreatePlaylistWithSongView: View {
    let song: Song
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    var user:User{
        authManager.currentUser!
    }
    @State private var playlistName = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.12),
                                                Color(red: 0.03, green: 0.03, blue: 0.06)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    SongHeaderView(song: song)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playlist Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("My Awesome Playlist", text: $playlistName)
                            .focused($isTextFieldFocused)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal)

                    Button(action: createPlaylist) {
                        Text("Create Playlist")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                                                       startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                    }
                    .disabled(playlistName.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        
    }

    private func createPlaylist() {
        Task { @MainActor in

            let newPlaylist = Playlist(
                name: playlistName,
                owner: user
            )

            context.insert(newPlaylist)

            let entry = PlaylistSongs(
                order: 1,
                playlist: newPlaylist,
                song: song
            )

            newPlaylist.entries.append(entry)

            do {
                try context.save()
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}


extension Array where Element == Artist {
    func formatted() -> String {
        map(\.name).joined(separator: ", ")
    }
}
