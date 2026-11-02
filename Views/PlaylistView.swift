import SwiftUI
import SwiftData

struct PlaylistView: View {

    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var playlist: Playlist

    @State private var cachedEntries: [PlaylistSongs] = []
    @State private var songs: [Song] = []
    @State private var animate  = false

    var body: some View {
        ZStack {

            backgroundView

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    headerSection

                    controlsSection

                    songsSection
                }
                .padding(.bottom, 100)
            }.scrollIndicators(.hidden)
            .onAppear(perform: setupView)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 30)
            .animation(.easeOut(duration: 0.6), value: animate)
        }
    }
}

extension PlaylistView {

    private var backgroundView: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color.black,
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

            Circle()
                .fill(.pink.opacity(0.15))
                .frame(width: 200)
                .blur(radius: 80)
                .offset(x: 180, y: -120)
        }
    }
}

extension PlaylistView {

    private var headerSection: some View {
        VStack(spacing: 20) {

            ZStack {

                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.12),
                                .white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                    .frame(width: 240, height: 240)

                playlistArtwork
            }

            VStack(spacing: 8) {

                Text(playlist.name)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(songs.count) songs")
                    .foregroundStyle(.gray)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var playlistArtwork: some View {

        if playlist.name == "Liked Songs" {

            ZStack {

                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 210, height: 210)
                    .shadow(color: .purple.opacity(0.5), radius: 25)

                Image(systemName: "heart.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(.white)
            }

        } else {

            SongCoversGrid(songs: songs)
                .frame(width: 210, height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.4), radius: 20, y: 12)
        }
    }
}

extension PlaylistView {

    private var controlsSection: some View {

        let isCurrentPlaylistPlaying =
            audioManager.isPlaying &&
            audioManager.playlistTitle == playlist.name

        return HStack(spacing: 20) {

            Button {
                withAnimation {
                    playlist.shuffle.toggle()
                }
            } label: {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundStyle(playlist.shuffle ? .green : .gray)
            }
            .padding(.horizontal)

            if playlist.name != "Liked Songs" {

                Button {
                    deletePlaylist()
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            if !playlist.entries.isEmpty {

                Button {

                    if  audioManager.playlistTitle == playlist.name {
                        audioManager.togglePlayPause()

                    } else {

                        if let song = playlist.shuffle
                            ? songs.randomElement()
                            : songs.first {

                            audioManager.playSong(
                                song,
                            
                                from: songs,
                                playlistName: playlist.name,
                                isOnlySong: false,
                                songIndex: 0,
                                shuffle: playlist.shuffle
                            )
                        }
                    }

                } label: {

                    ZStack {

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: .green.opacity(0.5), radius: 18)

                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 72, height: 72)

                        Image(systemName:
                                isCurrentPlaylistPlaying
                              ? "pause.fill"
                              : "play.fill"
                        )
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

extension PlaylistView {

    private var songsSection: some View {

        VStack(spacing: 12) {

            ForEach(Array(cachedEntries.enumerated()), id: \.element.id) { index, entry in

                PlaylistSongRow(
                    index: index,
                    entry: entry,
                    playlist: playlist,
                    songs: songs,
                    cachedEntries: $cachedEntries,
                    songsBinding: $songs
                )
                .environmentObject(audioManager)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

extension PlaylistView {

    private func setupView() {

        animate = true

        cachedEntries = playlist.entries.sorted {
            $0.order < $1.order
        }

        songs = cachedEntries.map(\.song)

        audioManager.isShowingMiniPlayer = false
        audioManager.isShowingMiniPlayerBottom = true
    }

    private func deletePlaylist() {

        context.delete(playlist)

        do {
            try context.save()
            dismiss()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct PlaylistSongRow: View {

    @EnvironmentObject var audioManager: AudioPlayerManager

    let index: Int
    let entry: PlaylistSongs
    let playlist: Playlist
    let songs: [Song]

    @Binding var cachedEntries: [PlaylistSongs]
    @Binding var songsBinding: [Song]

    var body: some View {

        HStack(spacing: 8) {

            ZStack {

                Text("\(index + 1)")
                    .foregroundColor(.gray)
            }
            .frame(width: 40)

            SongPlaylistView(
                onDelete: {

                    cachedEntries.removeAll {
                        $0.id == entry.id
                    }

                    songsBinding = cachedEntries.map(\.song)
                },
                song: entry.song,
                order: index,
                playlist: playlist,
                entry: entry
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white.opacity(0.06))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(0.25),
            radius: 12,
            y: 8
        )
        .contentShape(Rectangle())
        .onTapGesture {

            audioManager.playSong(
                entry.song,
                from: songs,
                playlistName: playlist.name,
                isOnlySong: false,
                songIndex: index,
                shuffle: playlist.shuffle
            )
        }
    }
}
