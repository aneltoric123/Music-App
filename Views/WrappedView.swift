//
//  WrappedView.swift
//  music
//
//  Created by Anel Torić on 2. 10. 2026.
//
import SwiftUI
import SwiftData
import Foundation
struct WrappedView: View{
    @EnvironmentObject var authManager:AuthManager
    @EnvironmentObject var audioPlayer:AudioPlayerManager
    @Environment(\.modelContext) private var context:ModelContext
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
        }
    }
    
}
struct ArtistWrappedView: View{
    var body: some View{
        
    }
}
struct SongWrappedView: View{
    var body: some View{
        
    }
}
