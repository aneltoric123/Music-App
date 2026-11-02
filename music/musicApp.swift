//
//  musicApp.swift
//  music
//
//  Created by xxxxxxxxxxx on 22. 2. 26.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct musicApp: App {
    let container: ModelContainer
    @StateObject private var authManager:AuthManager
    @StateObject private var audioManager: AudioPlayerManager

    init() {
        do {
            let schema = Schema([
                Song.self,
                Album.self
                ,AlbumSearchHistory.self,
                Artist.self,
                Genre.self,
                SearchHistory.self,
                Playlist.self,
                User.self,
                PlayHistory.self,
                SongSearchHistory.self,
                ArtistSearchHistory.self,
                PlaylistSongs.self
               
                
            ])
            
           
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            _ = ModelContext(container)
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    
                try AVAudioSession.sharedInstance().setActive(true)
                
            } catch {
                print("Failed to set audio session")
            }
            let auth = AuthManager(
                context: container.mainContext
            )
            let manager = AudioPlayerManager(
                context: container.mainContext
            )
        
            auth.audioManager = manager
            manager.authManager = auth

            _authManager = StateObject(
                wrappedValue: auth
            )

            _audioManager = StateObject(
                wrappedValue: manager
            )
            
        } catch {
            fatalError("Failed to initialize Swift Data: \(error)")
        }
    }

    

    var body: some Scene {
        WindowGroup {

            if authManager.isLoggedIn && !authManager.isUnlocked {
                ProgressView("Unlocking...")
            }
            else if authManager.isLoggedIn && authManager.isUnlocked{
                
                ContentView()
                    .task {
                            audioManager.restoreQueueIfNeeded()
                        }
                    
                    .environmentObject(audioManager)
                    .environmentObject(authManager)
                    
                    
            }
            
            else {
                LoginView()
                    .environmentObject(authManager)
                    
            }
        }
        .modelContainer(container)
    }
} 

