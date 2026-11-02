//
//  AlbumView.swift
//  music
//
//  Created by Anel Torić on 7. 8. 2026.
//
import SwiftUI
import Foundation
import SwiftData
struct AlbumView: View{
    @EnvironmentObject var audioManager:AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    var album:Album
    var isSearch:Bool
   
    var body:some View{
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
        
            ScrollView{
                VStack(spacing:10){
                    AsyncCover(song: album.songs.first!, size: 150)
                   
                    
                    Text(album.name).foregroundColor(.white).font(.subheadline).fontWeight(.bold)
                    
                    Text(formatArtists(album.artists)).foregroundColor(.gray)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    HStack{
                        Button{
                            
                            audioManager.playSong(album.songs.randomElement()!, from: album.songs, isOnlySong:false,shuffle:true)
                        }
                        label:{
                            Image(systemName: "shuffle").font(.title2)
                        }
                        Spacer()
                        Button{
                            audioManager.playSong(album.songs.first!, from: album.songs,playlistName:album.name, isOnlySong: false)
                        }label:{
                            
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

                                Image(systemName:"play.fill"
                                )
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.black)
                            }
                        }
                        
                    }.padding(.horizontal)
                    
                    
                    ForEach(Array(album.songs.enumerated()),id: \.element.id_song){index,song in
                        HStack(spacing:8){
                            var isPlaylistSong:Bool{
                                audioManager.currentSong?.id_song == song.id_song
                            }
                            ZStack{
                                Text("\(index + 1)").foregroundColor(isPlaylistSong ? .green : .gray)
                            }
                            VStack(spacing:5){
                                Text(song.title.split(separator: " - ")[0]).lineLimit(1).truncationMode(.tail).font(.system(size: 17, weight: .medium)).foregroundColor(isPlaylistSong ? .green : .gray).clipped().frame(maxWidth: .infinity,alignment: .leading)
                                Text(song.title.split(separator: " - ")[1]).lineLimit(1).truncationMode(.tail).font(.system(size: 14, weight: .medium)).foregroundColor(isPlaylistSong ? .green : .gray).clipped().frame(maxWidth: .infinity,alignment: .leading)
                                
                            }.contentShape(Rectangle()).onTapGesture{
                                audioManager.playSong(song, from: album.songs.suffix(album.songs.count - index), playlistName:album.name, isOnlySong: false)
                            }
                            
                            
                            Spacer()
                            HStack{
                                Menu {
                                    NavigationLink(destination: AddSongPlaylistView(song: song)){
                                        Label("Add to playlist",systemImage: "plus.circle")
                                    }
                                    
                                }label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title3).foregroundColor(.secondary)
                                }.padding(.trailing).compositingGroup()
                            }
                        }.padding(.vertical,5).padding(.horizontal)
                    }
                }.padding(.bottom,audioManager.currentSong != nil ? 100 : 10)
            }.scrollIndicators(.hidden)
        }.onAppear{
            if audioManager.currentSong != nil{
                audioManager.isShowingMiniPlayer = false
                audioManager.isShowingMiniPlayerBottom = true
            }
        }
    }
        
    
        func formatArtists(_ artists:[Artist]) -> String{
            return artists.map {$0.name}.joined(separator: ", ")
        }
    
}
