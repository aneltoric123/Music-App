//
//  StatView.swift
//  music
//
//  Created by Anel Torić on 9. 5. 2026.
//
import SwiftUI
import Foundation
import SwiftData



private extension Color {
    static let statCardTop = Color.white.opacity(0.14)
    static let statCardBottom = Color.white.opacity(0.05)
}



struct StatView: View {
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager

    @State private var timeFrame = "All"
    @State private var typeStat = "Songs"
    @State private var listTransitionID = UUID()   

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 18) {
                header

                SegmentedToggle(
                    selection: $typeStat.animation(.spring(response: 0.35, dampingFraction: 0.8)),
                    options: ["Songs", "Artists"],
                    accent: .cyan
                )

                SegmentedToggle(
                    selection: $timeFrame.animation(.spring(response: 0.35, dampingFraction: 0.8)),
                    options: ["24H", "7D", "30D", "All"],
                    accent: .mint
                )

                Group {
                    if typeStat == "Artists" {
                        FavouriteArtists(currentUser: authManager.currentUser!, timeFrame: $timeFrame)
                            .id("artists-\(listTransitionID)")
                    } else {
                        FavouriteSongs(username: authManager.currentUser!.username, timeFrame: $timeFrame)
                            .id("songs-\(listTransitionID)")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
        .onChange(of: typeStat) { _, _ in
            listTransitionID = UUID()
        }


        .onAppear {
            audioPlayer.isShowingMiniPlayer = false
            audioPlayer.isShowingMiniPlayerBottom = true
        }
    }

   

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.05, blue: 0.35),
                Color(red: 0.25, green: 0.08, blue: 0.45),
                Color(red: 0.45, green: 0.10, blue: 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Taste")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("What you've been playing")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .pink], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .cyan.opacity(0.5), radius: 8)
        }
        .padding(.top, 12)
    }
}


struct SegmentedToggle: View {
    @Binding var selection: String
    let options: [String]
    var accent: Color = .blue

    @Namespace private var indicatorNS

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(option)
                        .font(.subheadline.weight(selection == option ? .bold : .semibold))
                        .foregroundStyle(selection == option ? .white : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background {
                            if selection == option {
                                Capsule()
                                    .fill(accent.gradient)
                                    .matchedGeometryEffect(id: "segmentIndicator", in: indicatorNS)
                                    .shadow(color: accent.opacity(0.45), radius: 10, y: 4)
                            }
                        }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(5)
        .background(Capsule().fill(Color.black.opacity(0.25)))
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}


struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}



struct StatRow<CardContent: View>: View {
    let rank: Int
    let count: Int
    @ViewBuilder let content: () -> CardContent

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            RankBadge(rank: rank)

            content()

            Spacer(minLength: 8)

            AnimatedCountLabel(value: count)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(appeared ? 0.15 : 0), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        .scaleEffect(appeared ? 1 : 0.92)
        .offset(x: appeared ? 0 : 40)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(rank % 20) * 0.04)) {
                appeared = true
            }
        }
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [.statCardTop, .statCardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct RankBadge: View {
    let rank: Int

    private var color: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.3)
        default: return .white.opacity(0.35)
        }
    }

    var body: some View {
        Text("\(rank)")
            .font(.system(.body, design: .rounded).weight(.heavy))
            .foregroundStyle(rank <= 3 ? color : .white.opacity(0.6))
            .frame(width: 30, height: 30)
            .background(
                Circle()
                    .fill(rank <= 3 ? AnyShapeStyle(color.opacity(0.25)) : AnyShapeStyle(Color.white.opacity(0.08)))
            )
            .overlay(
                Circle().strokeBorder(rank <= 3 ? AnyShapeStyle(color.opacity(0.6)) : AnyShapeStyle(Color.clear), lineWidth: 1.5)
            )
    }
}

struct AnimatedCountLabel: View {
    let value: Int
    @State private var displayed: Double = 0

    var body: some View {
        Text("\(Int(displayed))")
            .monospacedDigit()
            .contentTransition(.numericText())
            .onAppear { animateToValue() }
        .onChange(of: value) { _, _ in animateToValue() }
    }

    private func animateToValue() {
        displayed = 0
        withAnimation(.easeOut(duration: 0.6)) {
            displayed = Double(value)
        }
    }
}


struct FavouriteSongs: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    let username: String
    @Binding var timeFrame: String

    @Query var userPlayHistory: [PlayHistory]

    init(username: String, timeFrame: Binding<String>) {
        self.username = username
        self._timeFrame = timeFrame

        _userPlayHistory = Query(
            filter: #Predicate<PlayHistory> { history in
                history.user?.username == username
            },
            sort: \PlayHistory.song?.title
        )
    }

    var filteredHistory: [PlayHistory] {
        guard timeFrame != "All" else { return userPlayHistory }
        return userPlayHistory.filter { $0.playedAt >= startDate(for: timeFrame) }
    }

    var songPlayCounts: [(song: Song, count: Int)] {
        Dictionary(grouping: filteredHistory) { $0.song }
            .compactMap { key, value in
                guard let song = key else { return nil }
                return (song, value.count)
            }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if songPlayCounts.isEmpty {
                    EmptyStatsPlaceholder()
                } else {
                    ForEach(Array(songPlayCounts.enumerated()), id: \.element.song.id) { index, item in
                        StatRow(rank: index + 1, count: item.count) {
                            SongStatContent(song: item.song)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 100)
        }
    }

    func startDate(for timeFrame: String) -> Date {
        let calendar = Calendar.current
        switch timeFrame {
        case "24H": return calendar.date(byAdding: .hour, value: -24, to: Date())!
        case "7D":  return calendar.date(byAdding: .day, value: -7, to: Date())!
        case "30D": return calendar.date(byAdding: .day, value: -30, to: Date())!
        default:    return Date.distantPast
        }
    }
}

struct SongStatContent: View {
    let song: Song
    var parsedTitle:String {
        let parts = song.title.components(separatedBy: " - ")
            return parts[0] + " - " + parts[1]
    }

    var body: some View {
        HStack(spacing: 12) {
            ArtworkImage(song: song)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title.split(separator: " - ")[0])
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.tail)
                
                Text(song.title.split(separator: " - ")[1])
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


struct FavouriteArtists: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    var currentUser: User
    @Binding var timeFrame: String

    @Query var userPlayHistory: [PlayHistory]

    init(currentUser: User, timeFrame: Binding<String>) {
        self.currentUser = currentUser
        self._timeFrame = timeFrame

        let username = currentUser.username
        _userPlayHistory = Query(
            filter: #Predicate<PlayHistory> { history in
                history.user?.username == username
            },
            sort: \PlayHistory.song?.title
        )
    }

    var filteredHistory: [PlayHistory] {
        guard timeFrame != "All" else { return userPlayHistory }
        return userPlayHistory.filter { $0.playedAt >= startDate(for: timeFrame) }
    }

    var artistPlayCounts: [(artist: Artist, count: Int)] {
        let allArtists = filteredHistory.flatMap { $0.song?.artists ?? [] }
        return Dictionary(grouping: allArtists) { $0 }
            .map { (artist: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if artistPlayCounts.isEmpty {
                    EmptyStatsPlaceholder()
                } else {
                    ForEach(Array(artistPlayCounts.enumerated()), id: \.element.artist.id) { index, item in
                        StatRow(rank: index + 1, count: item.count) {
                            ArtistStatContent(artist: item.artist)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 100)
        }
    }

    func startDate(for timeFrame: String) -> Date {
        let calendar = Calendar.current
        switch timeFrame {
        case "24H": return calendar.date(byAdding: .hour, value: -24, to: Date())!
        case "7D":  return calendar.date(byAdding: .day, value: -7, to: Date())!
        case "30D": return calendar.date(byAdding: .day, value: -30, to: Date())!
        default:    return Date.distantPast
        }
    }
}

struct ArtistStatContent: View {
    var artist: Artist
    @Query private var latestSongsByArtist: [Song]

    init(artist: Artist) {
        self.artist = artist
        let artistName = artist.name
        self._latestSongsByArtist = Query(
            filter: #Predicate<Song> { song in
                song.artists.contains(where: { $0.name == artistName })
            },
            sort: \Song.persistentModelID,
            order: .reverse
        )
    }

    var representativeSong: Song? {
        latestSongsByArtist.first(where: { $0.artists.contains(where: { $0.id == artist.id }) })
            ?? latestSongsByArtist.first
    }

    var body: some View {
        HStack(spacing: 12) {
            
            if let song = representativeSong {
                ArtworkImage(song: representativeSong!)
                    .frame(width: 52, height: 52)
            } else {
                ZStack {
                    Circle().fill(Color.white.opacity(0.1))
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: 52, height: 52)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ArtworkImage: View {
    let song: Song
    
    var body: some View {
        
            if let url = resolveCoverURL(for: song){
                AsyncCover(song: song, size: 52)
                        } else {
                            Image(systemName: "music.note")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .foregroundColor(.gray)
                        }
                    }
    
}

struct EmptyStatsPlaceholder: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.35))
                .scaleEffect(pulse ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

            Text("No plays yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))
            Text("Start listening and your favourites will appear here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .onAppear { pulse = true }
    }
}
