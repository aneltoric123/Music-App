//
//  HomeView.swift
//  music
//
//  Created by Anel Torić on 26. 2. 26.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var audioManager:AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    @Binding var navPath: NavigationPath
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HeroSection()

                    SectionView(title: "Recently Played") {
                        RecentlyPlayedGrid(navPath: $navPath)
                    }

                    SectionView(title: "New Releases for you") {
                        NewSongGridFollowing(navPath: $navPath)
                    }

                    SectionView(title: "New Releases") {
                        NewSongGrid(navPath: $navPath)
                    }

                    SectionView(title: "Recommended for You") {
                        SongRowGrid(navPath: $navPath)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
        
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        .onAppear{
            audioManager.isShowingMiniPlayer = true
        }
    }
}

struct HeroSection: View {
    @EnvironmentObject var auth: AuthManager
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good afternoon,\(auth.username)")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("What would you like to listen to?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .padding(.bottom, 20)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            content
        }
    }
}

struct RecentlyPlayedGrid: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var auth:AuthManager
    var user: User {
        auth.currentUser!
    }
    var likedSongsPlaylist:Playlist { auth.likedSongsPlaylist!
    }
    
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @Binding var navPath: NavigationPath
    @State private var recentlyPlayed: [Song] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showToast:Bool = false
    @State private var toastMessage:String = ""
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(height: 180)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if recentlyPlayed.isEmpty {
                Text("No recently played songs")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(recentlyPlayed) { song in
                            NavigationLink(destination: SongView(song: song,navPath: $navPath)){
                                SongCardViewHome(song: song, type: .recent)
                            }.buttonStyle(PlainButtonStyle()).onTapGesture {
                                navPath.append(Route.song(song))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchRecentlyPlayed()
        }
    }
    
    private func fetchRecentlyPlayed() {
        
        guard let currentUser = auth.currentUser else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            
            let descriptor = FetchDescriptor<PlayHistory>(
                sortBy: [
                    SortDescriptor(
                        \PlayHistory.playedAt,
                         order: .reverse
                    )
                ]
            )
           
            
            let history = try context.fetch(descriptor)
            let userID = currentUser.id
            let userHistory = history.filter {
                $0.user?.id == userID
                
            }.prefix(20)
            
            var seen = Set<UUID>()
            recentlyPlayed = userHistory.compactMap { history in
                guard let song = history.song else { return nil }
                
                if seen.contains(song.id) {
                    return nil
                } else {
                    seen.insert(song.id)
                    return song
                }
            }
            
            
        } catch {
            
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
struct NewSongGridFollowing: View {
    @Query private var allSongs: [Song]
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    @State private var latestSongs: [Song] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Binding var navPath: NavigationPath
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @State private var showToast:Bool = false
    @State private var toastMessage:String = ""
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(height: 180)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if latestSongs.isEmpty {
                Text("Start Following artists to see their new songs!")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(latestSongs) { song in
                            NavigationLink(destination:SongView(song: song,navPath: $navPath)){
                                SongCardViewHome(song: song, type: .new)
                            }.buttonStyle(PlainButtonStyle()).onTapGesture {
                                navPath.append(Route.song(song))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchLatestSongsFollowing()
            
        }
    }

    private func fetchLatestSongsFollowing() {
        isLoading = true
        errorMessage = nil

        var artistFollowingSongs: [Song] {
            guard let followedArtists = authManager.currentUser?.followedArtists else {
                return []
            }

            return allSongs.filter { song in
                song.artists.contains { artist in
                    followedArtists.contains(artist)
                }
            }
        }
        let sorted = Array(artistFollowingSongs.sorted{ $0.dateAdded > $1.dateAdded}.prefix(20))
        latestSongs = sorted
        isLoading = false
    }
}

struct NewSongGrid: View {
    @Query private var allSongs: [Song]
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    @State private var latestSongs: [Song] = []
    @State private var isLoading = true
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @State private var errorMessage: String?
    @Binding var navPath: NavigationPath
    @State private var showToast:Bool = false
    @State private var toastMessage:String = ""
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(height: 180)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if latestSongs.isEmpty {
                Text("No new songs found")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(latestSongs) { song in
                            NavigationLink(destination:
                                            SongView(song: song,navPath: $navPath)){
                                SongCardViewHome(song: song, type: .new)
                            }.buttonStyle(PlainButtonStyle()).onTapGesture {
                                navPath.append(Route.song(song))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            
            fetchLatestSongs()
            
        }
    }

    private func fetchLatestSongs() {
        isLoading = true
        errorMessage = nil

        var descriptor = FetchDescriptor<Song>(
            sortBy: [SortDescriptor(\Song.dateAdded, order: .reverse)]
        )
        descriptor.fetchLimit = 20

        do {
            latestSongs = try context.fetch(descriptor)
            
            if latestSongs.isEmpty {
                
            }
        } catch {
            errorMessage = error.localizedDescription
          
        }

        isLoading = false
    }
    private func fetchLatestSongsFollowing() {
        isLoading = true
        errorMessage = nil

        var artistFollowingSongs: [Song] {
            guard let followedArtists = authManager.currentUser?.followedArtists else {
                return []
            }

            return allSongs.filter { song in
                song.artists.contains { artist in
                    followedArtists.contains(artist)
                }
            }
        }
        let sorted = artistFollowingSongs.sorted{ $0.dateAdded < $1.dateAdded}
        latestSongs = sorted
        isLoading = false
    }
}


struct SongRowGrid: View {
    @Environment(\.modelContext) private var context
    @State private var recommendedSongs: [Song] = []
    @State private var isLoading = true
    @EnvironmentObject var authManager:AuthManager
    @State private var errorMessage: String?
    @Binding var navPath: NavigationPath
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @State private var showToast:Bool = false
    @State private var toastMessage:String = ""
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(height: 180)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if recommendedSongs.isEmpty {
                Text("No recommendations available")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(recommendedSongs) { song in
                            NavigationLink(destination: SongView(song: song,navPath: $navPath)){
                                SongCardViewHome(song: song, type: .recommended)
                            }.buttonStyle(PlainButtonStyle()).onTapGesture {
                                navPath.append(Route.song(song))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchRecommendedSongs()
        }
    }
    

    private func fetchRecommendedSongs() {
        isLoading = true
        errorMessage = nil

        do {
            let descriptor = FetchDescriptor<Song>()
            let allSongs = try context.fetch(descriptor)
            let recSongs = allSongs.prefix(20)

            if allSongs.isEmpty {
               
                recommendedSongs = []
            } else {
                recommendedSongs = Array(recSongs)
               
            }
        } catch {
            errorMessage = error.localizedDescription
           
        }

        isLoading = false
    }
}


enum SongCardType {
    case recent, new, recommended
}

struct SongCardViewHome: View {
    let song: Song
    let type: SongCardType
    
    var artistText: String {
        song.artists.map { $0.name }.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
           
            ZStack(alignment: .bottomTrailing) {
                AlbumCoverImage(song: song)
                    
               
                switch type {
                case .recent:
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .padding(4)
                case .new:
                    Text("NEW")
                        .font(.caption2)
                        .bold()
                        .padding(4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .padding(4)
                case .recommended:
                    Image(systemName: "heart.text.square")
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            .frame(width: 140, height: 140)
            .cornerRadius(8)

           
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(artistText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 140)
        }
        .frame(width: 140)
    }
}


struct AlbumCoverImage: View {
    let song: Song

    var body: some View {
        Group {
            Image(song.coverpath)
                    .resizable()
                    .scaledToFill()
            }
            
        
        .frame(width: 140, height: 140)
        .clipped()
    }
}
