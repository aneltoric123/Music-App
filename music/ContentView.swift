//
//  ContentView.swift
//  music
//
//  Created by Anel Torić on 22. 2. 26.
//

import SwiftUI
import AVFoundation
import SwiftData

enum Route: Hashable {
    case song(Song)
    case queue
    case addQueuePlaylist([Song])
    case addSingleSong(Song)
}
struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var context
    @State private var showToast:Bool = false
    @State private var toastMessage:String = ""
    @State private var navPath = NavigationPath()
    var likedSongsPlaylist:Playlist { authManager.likedSongsPlaylist!
    }
    var likedSongs:[Song] {likedSongsPlaylist.songs}
    @Query private var allSongs: [Song]
    var body: some View {
        NavigationStack(path: $navPath){
            
                TabView {
                    HomeView(navPath: $navPath).tabItem{
                        Label("Home",systemImage: "house")
                        
                    }
                    SearchView().tabItem{
                        Label("Search",systemImage: "magnifyingglass")
                    }
                    LibraryView().tabItem{
                        Label("Library",systemImage: "folder.fill")
                    }
                    SettingsView().tabItem{
                        Label("Settings",systemImage: "gearshape.fill")
                    }
                }
                .task{
                    if allSongs.isEmpty {
                        importData(context: context)
                    }
                    else{
                        
                        deleterepeatArtists()
                    }
                    
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {

                    case .queue:
                        QueueView(navPath: $navPath)

                    case .song(let song):
                        SongView(song: song, navPath: $navPath)

                    case .addQueuePlaylist(let songs):
                        AddSongsPlaylistView(songs: songs,navPath:$navPath)

                    case .addSingleSong(let song):
                        AddSongPlaylistView(song: song)
                    }
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
                
                .environmentObject(audioManager).environmentObject(authManager)
            
               
        } .overlay(alignment: .bottom) {
            if audioManager.currentSong != nil && audioManager.isShowingMiniPlayer{
                    MiniPlayerView(navPath:$navPath)
                    .padding(.bottom,50)
                    .transition(.move(edge: .bottom))
                }
            else if  audioManager.currentSong != nil && audioManager.isShowingMiniPlayerBottom{
                MiniPlayerView(navPath:$navPath)
                .transition(.move(edge: .bottom))
            }
            }
        
    }


    func clearDatabase() {
        let container = try! ModelContainer(for: Song.self, Artist.self)
        let context = ModelContext(container)

        do {
           
            let songs = try context.fetch(FetchDescriptor<Song>())
            for song in songs {
                context.delete(song)
            }
        
            try context.save()
            print("Database cleared successfully.")
        } catch {
            print("Error clearing database: \(error)")
        }
    }
    private func deleterepeatArtists(){
        do{
            let descriptor = FetchDescriptor<Artist>()
            let result = try context.fetch(descriptor)
            for artist in result {
                if artist.songs.count == 0{
                    context.delete(artist)
                }
            }
            
        }
        catch{
            print("\(error)")
        }
    }

    private func checkAndImport() {
        do {
            let descriptor = FetchDescriptor<Song>()
            let count = try context.fetch(descriptor).count
            
            if count == 0 {
                print("Database empty. Importing JSON...")
                importData(context: context)
            } else {
                print("Database already contains \(count) songs")
            }
        } catch {
            print("Check failed:", error)
        }
    }


    }
    
    #Preview {
        ContentView()
    }

