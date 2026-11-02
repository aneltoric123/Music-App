//
//  SettingsView.swift
//  music
//
//  Created by Anel Torić on 2. 3. 26.
//

import SwiftUI
import SwiftData
import Foundation

struct SettingsView:View{
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioManager:AudioPlayerManager
    @State private var showingImporter:Bool = false
    @State private var showingImporterCover:Bool = false
    var faceIDEnabled = true
    var body: some View{
        ZStack{
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
        VStack(spacing: 20){
            Text("Settings").padding().font(.system(size:34, weight: .bold,design: .default))
            NavigationLink(destination: StatView()){
                HStack(spacing:8){
                    Text("View Stats").font(.headline).foregroundColor(.white)
                }.foregroundStyle(.white)
                    .padding()
                    
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .green.opacity(0.4), radius: 10)
            }.background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ).cornerRadius(30)
            .padding(.horizontal)
            NavigationLink(destination: WrappedView()){
                HStack(spacing:8){
                    Text("Your Wrapped").font(.headline).foregroundColor(.white)
                }.foregroundStyle(.white)
                    .padding()
                    
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .green.opacity(0.4), radius: 10)
            }.background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ).cornerRadius(30)
            .padding(.horizontal)
            Button(action: showImport) {
                HStack(spacing: 8) {
                    Text("Import Songs").font(.headline).foregroundColor(.white)
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .green.opacity(0.4), radius: 10)
            }
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(30)
            .padding(.horizontal)
            .buttonStyle(.plain)
            Button(action: showImportCover) {
                HStack(spacing: 8) {
                    Text("Import Covers").font(.headline).foregroundColor(.white)
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .green.opacity(0.4), radius: 10)
            }
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(30)
            .padding(.horizontal)
            .buttonStyle(.plain)
                
            
            HStack{
                Button{
                    if audioManager.isPlaying{
                        audioManager.togglePlayPause()
                    }
                    authManager.logout()
                }
                label: {
                    Text("Logout")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .green.opacity(0.4), radius: 10)
                        .cornerRadius(30)
                }
            }
            .sheet(isPresented: $showingImporter) {
                FolderImporter { mp3URLs in
                    showingImporter = false
                    Task { await audioManager.importSongs(from: mp3URLs) }
                   print("Found \(mp3URLs.count) songs!")
                    
                }
            }
            .sheet(isPresented: $showingImporterCover) {
                FolderImporterCover { mp3URLs in
                    showingImporterCover = false
                    Task { await audioManager.importCovers(from: mp3URLs) }
                   print("Found \(mp3URLs.count) songs!")
                    
                }
            }
            .padding(.horizontal)
            
            
        }
        .onAppear{
            audioManager.isShowingMiniPlayer = true
            audioManager.isShowingMiniPlayerBottom = false
        }
    }
}
    @MainActor func showImport(){
        showingImporter = true
    }
    @MainActor func showImportCover(){
        showingImporterCover = true
    }
}
