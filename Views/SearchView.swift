//
//  Search.swift
//  music
//
//  Created by Anel Torić on 2. 3. 26.
//

import SwiftUI
import Foundation
import SwiftData

struct SearchView: View {
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    var user:User{
        authManager.currentUser!
    }
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    @State private var showToast = false
    @State private var toastMessage = ""
    var likedSongsPlaylist:Playlist {
            authManager.likedSongsPlaylist!
        
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @State private var searchResultsSong: [Song] = []
    @State private var searchResultsArtist: [Artist] = []
    @State private var searchResultsAlbum: [Album] = []
    @State private var searchResultsSongAlbum:[Song] = []
    @Environment(\.modelContext) private var context
    enum UnifiedSearch: Identifiable {
        case search(SearchHistory)
        case song(SongSearchHistory)
        case artist(ArtistSearchHistory)
        case album(AlbumSearchHistory)
        
        var id: UUID {
            switch self {
            case .search(let s): return s.id
            case .song(let s): return s.id
            case .artist(let a): return a.id
            case .album(let a): return a.id
            }
        }
        
        var date: Date {
            switch self {
            case .search(let s): return s.date
            case .song(let s): return s.date
            case .artist(let a): return a.date
            case .album(let a): return a.date
            }
        }
    }
    var combinedSearches: [UnifiedSearch] {

        guard let user = authManager.currentUser else {
            return []
        }

        let combined =
        user.searchHistory.prefix(100).map(UnifiedSearch.search) +
        user.songSearchHistory.prefix(100).map(UnifiedSearch.song) +
        user.artistSearchHistory.prefix(100).map(UnifiedSearch.artist) +
        user.albumSearchHisotry.prefix(100).map(UnifiedSearch.album)

        return combined
            .sorted { $0.date > $1.date }
            .prefix(30)
            .map { $0 }
    }
    
   
    var body: some View {
        ZStack(alignment: .top){
            
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
            VStack{
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search songs and artists", text: $searchText)
                        .focused($isFocused)
                        .submitLabel(.search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .onSubmit { performSearch() }
                        .onChange(of: searchText) { _, _ in
                            searchTask?.cancel()
                            
                            searchTask = Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                
                                if !Task.isCancelled {
                                    updateSearchResults()
                                }
                            }
                        }
                        .onChange(of: isFocused){
                            if isFocused{
                                audioPlayer.isShowingMiniPlayer = false
                                audioPlayer.isShowingMiniPlayerBottom = false
                            }
                            else{
                                audioPlayer.isShowingMiniPlayer = true
                                audioPlayer.isShowingMiniPlayerBottom = false
                            }
                        }
                    if !searchText.isEmpty {
                        Button {
                            withAnimation {
                                searchText = ""
                                isFocused = false
                                isSearching = false
                                searchResultsSong = []
                                searchResultsArtist = []
                                searchResultsSongAlbum = []
                                searchResultsAlbum = []
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    } else {
                        Button("Cancel") { isFocused = false; audioPlayer.isShowingMiniPlayer = true;
                            audioPlayer.isShowingMiniPlayerBottom = false
                            isSearching = false
                            
                        }
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 8)
                    if isSearching {
                        ScrollView{
                            Section {
                                
                                ForEach(searchResultsArtist){
                                    artist in
                                    
                                    NavigationLink(destination: NewArtist(artist: artist)
                                        .onAppear {
                                            performSearchArtist(artist: artist)
                                        }
                                    ) {
                                        ArtistSearchView(artist: artist)
                                    }.contentShape(Rectangle())
                                        .navigationLinkIndicatorVisibility(.hidden)
                                    
                                    
                                }
                                
                                
                                ForEach(searchResultsAlbum){
                                    album in
                                    
                                    NavigationLink(destination: AlbumView(album: album, isSearch: true)
                                        .onAppear {
                                            performSearchAlbum(album:album)
                                        }.onTapGesture{
                                            isFocused = false
                                            isSearching = false
                                            searchTask?.cancel()
                                
                                            searchTask = nil
                                        }
                                    ) {
                                        AlbumSearchView(album: album)
                                    }.contentShape(Rectangle())
                                        .navigationLinkIndicatorVisibility(.hidden)
                                    
                                    
                                }
                                ForEach(searchResultsSong) { song in
                                    Button {
                                        audioPlayer.playSong(song, from: audioPlayer.playlist,isOnlySong: true)
                        
                                        isFocused = false
                                        isSearching = false
                                    } label: {
                                        SongSearchView(onLike: {
                                            toastMessage  = (!(likedSongs.contains(song))) ? "Removed from Liked Songs" : "Added to Liked Songs"
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showToast = true
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                showToast = false
                                            }
                                        }, song: song, likedSongsPlaylist: likedSongsPlaylist)
                                    }.contentShape(Rectangle())
                                    
                                    
                                }
                                ForEach(searchResultsSongAlbum) { song in
                                    Button {
                                        audioPlayer.playSong(song, from: audioPlayer.playlist,isOnlySong: true)

                                        isFocused = false
                                        isSearching = false
                                        searchTask?.cancel()
                                        searchTask = nil
                                    } label: {
                                        SongSearchView(onLike: {
                                            toastMessage  = (!(likedSongs.contains(song))) ? "Removed from Liked Songs" : "Added to Liked Songs"
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showToast = true
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                showToast = false
                                            }
                                        }, song: song, likedSongsPlaylist: likedSongsPlaylist)
                                    }.contentShape(Rectangle())
                                    
                                    
                                }
                                
                                
                            } header: {
                                if(searchResultsSong.count + searchResultsArtist.count + searchResultsAlbum.count + searchResultsSongAlbum.count == 0){
                                    Text("No results for \(searchText)")
                                }
                                else if(searchResultsSong.count + searchResultsArtist.count + searchResultsSongAlbum.count + searchResultsAlbum.count  == 1){
                                    Text("1 Result for \(searchText)")
                                }
                                else{
                                    Text("\(searchResultsSong.count + searchResultsArtist.count + searchResultsSongAlbum.count + searchResultsAlbum.count) Results for \(searchText)")
                                }
                            }.padding(.bottom,audioPlayer.currentSong != nil ? 100 : 10)
                        }.scrollIndicators(.hidden)
                        
                    } else {
                        if !combinedSearches.isEmpty {
                            ScrollView{
                                Section("Recent Searches") {
                                    
                                    ForEach(combinedSearches) { search in
                                        
                                        HStack {
                                            
                                            switch(search){
                                            case .search(let s):
                                                Button {
                                                    searchText = s.text
                                                    updateSearchResults()
                                                    isSearching = true
                                                    audioPlayer.isShowingMiniPlayerBottom = true
                                                    audioPlayer.isShowingMiniPlayer = false
                                                    performSearch()
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "clock.arrow.circlepath")
                                                        Text(s.text)
                                                    }.contentShape(Rectangle()).padding(.bottom,10)
                                                        .padding(.horizontal)
                                                   Spacer()
                                                }
                                                
                                            case .artist(let s):
                                                
                                                NavigationLink(destination: NewArtist(artist:s.artist)
                                                    .onAppear {
                                                        performSearchArtist(artist: s.artist)
                                                    }
                                                ) {
                                                    ArtistSearchView(artist: s.artist)
                                                }.contentShape(Rectangle())
                                                    .navigationLinkIndicatorVisibility(.hidden)
                                            case .album(let a):
                                                
                                                NavigationLink(destination: AlbumView(album:a.album, isSearch: true)
                                                    .onAppear {
                                                        performSearchAlbum(album: a.album)
                                                    }
                                                ) {
                                                    AlbumSearchView(album: a.album)
                                                }.contentShape(Rectangle())
                                                    .navigationLinkIndicatorVisibility(.hidden)
                                            case .song(let s):
                                                Button {
                                                    audioPlayer.playSong(s.song, from: audioPlayer.playlist,isOnlySong: true)
                                
                                                    isFocused = false
                                                    isSearching = false
                                                    searchTask?.cancel()
                                                    searchTask = nil
                                                } label: {
                                                    SongSearchView(onLike: {
                                                        toastMessage  = (!(likedSongs.contains(s.song))) ? "Removed from Liked Songs" : "Added to Liked Songs"
                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                        showToast = true
                                                        
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                            showToast = false
                                                        }
                                                    }, song: s.song, likedSongsPlaylist: likedSongsPlaylist)
                                                }.contentShape(Rectangle())
                                            
                                            }
                                            
                                            Button {
                                                deleteUnified(search)
                                            } label: {
                                                Image(systemName: "xmark").foregroundColor(.secondary)
                                            }
                                            .buttonStyle(BorderlessButtonStyle()).padding(.bottom,10).padding(.trailing)
                                        }
                                    }
                                }.padding(.bottom,audioPlayer.currentSong != nil ? 100 : 10)
                                
                                
                           
                            }.scrollIndicators(.hidden)
                    }
                }
            }.navigationTitle("Search")
                .onAppear{
                    isFocused = true
                    searchText = ""
                    audioPlayer.isShowingMiniPlayer = false
                    audioPlayer.isShowingMiniPlayerBottom = false
                }
                .navigationBarTitleDisplayMode(.inline)
                .onDisappear{
                    isFocused = false
                    isSearching = false
                    searchTask?.cancel()
                    searchTask = nil
                }
                
            
            VStack
            {
                Spacer()
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
                        .padding(.bottom, 140)
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                        .zIndex(999)
                }
            }
            .animation(.spring(duration: 0.4), value: showToast)

        }
    }
    func performSearchArtist(artist: Artist) {
        guard let user = authManager.currentUser else { return }

        if let existing = user.artistSearchHistory.first(where: { $0.artist == artist }) {
            existing.date = .now
        } else {
            let entry = ArtistSearchHistory(artist: artist, user: user)
            context.insert(entry)
        }

        try? context.save()
    }
    func performSearchAlbum(album: Album) {
        guard let user = authManager.currentUser else { return }

        if let existing = user.albumSearchHisotry.first(where: { $0.album == album }) {
            existing.date = .now
        } else {
            let entry = AlbumSearchHistory(album: album, user: user)
            context.insert(entry)
        }

        try? context.save()
    }
    private func updateSearchResults() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 3 else {
            isSearching = false
            searchResultsSong = []
            searchResultsArtist = []
            searchResultsAlbum = []
            searchResultsSongAlbum = []
            return
        }

        isSearching = true

        do {
            
            let matchedArtists = try context.fetch(
                FetchDescriptor<Artist>(
                    predicate: #Predicate {
                        $0.name.localizedStandardContains(trimmed)
                    },
                    sortBy: [SortDescriptor(\Artist.name)]
                )
            )

           
            
            
            let matchedAlbums = try context.fetch(
                FetchDescriptor<Album>(
                    predicate: #Predicate {
                        $0.name.localizedStandardContains(trimmed)
                    },
                    sortBy: [SortDescriptor(\Album.name)]
                )
            )
            
            
           
          
            let titleSongs2 = try context.fetch(
                FetchDescriptor<Song>(
                    predicate: #Predicate {
                        $0.title.localizedStandardContains(trimmed)
                    },
                    sortBy: [SortDescriptor(\Song.title)]
                )
            )
            var albumSongs:[Song] = []
            var titleSongs:[Song] = []
            for s in titleSongs2{
                let parts = s.title.split(separator:" - ")
                if (!parts[2].localizedStandardContains(parts[0]) && parts[2].localizedStandardContains(trimmed)){
                    albumSongs.append(s)
                }
                    else{
                    titleSongs.append(s)
                }
            }
           
    
            let artistSongMatches = matchedArtists.flatMap(\.songs)


            var seen = Set<Int>()

            
            searchResultsArtist = Array(matchedArtists.prefix(10))
            searchResultsAlbum = Array(matchedAlbums.prefix(20))
            searchResultsSong = Array((titleSongs.prefix(30) + artistSongMatches.prefix(20)).filter { song in
                seen.insert(song.id_song).inserted
            })
            searchResultsSongAlbum = Array(albumSongs.prefix(30))

        } catch {
            print("Search failed:", error)
            searchResultsSong = []
            searchResultsArtist = []
            searchResultsAlbum = []
            searchResultsSongAlbum = []
        }
    }
    
    func performSearch() {
        let trimmed = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard
            !trimmed.isEmpty,
            let user = authManager.currentUser
        else { return }

        if let existing = user.searchHistory.first(
            where: { $0.text == trimmed }
        ) {
            existing.date = .now
        } else {
            context.insert(
                SearchHistory(
                    text: trimmed,
                    user: user
                )
            )
        }
        try? context.save()
    }
   
    /* func printAllArtists(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<Artist>(
            sortBy: [SortDescriptor(\Artist.name)]
        )

        do {
            let allArtists = try context.fetch(fetchDescriptor)
            print("\n=== All Artists (\(allArtists.count)) ===")
            for (index, artist) in allArtists.enumerated() {
                print("""
                [\(index + 1)]
                - ID: \(artist.id)
                - Name: \(artist.name)
                - Songs: \(artist.songs.count)
                
                """)
            }
        } catch {
            print("Failed to fetch artists: \(error)")
        }
    }


*/
    func deleteUnified(_ item: UnifiedSearch) {
        switch item {
        case .search(let s):
            context.delete(s)
            user.searchHistory.removeAll(where:{ s.text == $0.text && user == s.user})
            
        case .song(let s):
            context.delete(s)
            user.songSearchHistory.removeAll(where:{ s.song == $0.song && user == s.user})
            
        case .artist(let a):
            context.delete(a)
            user.artistSearchHistory.removeAll(where:{ a.artist == $0.artist && user == a.user})
        case .album(let a):
            context.delete(a)
            user.albumSearchHisotry.removeAll(where: {a.album == $0.album && user == a.user})
        }
   
        
        do {
            try context.save()
        } catch {
            print("Failed to delete: \(error)")
        }
    }
    func deleteSearch(_ search: SearchHistory) {
        context.delete(search)
        do {
                try context.save()
                } catch {
                    print("Failed to delete search: \(error)")
                }
    }
}
