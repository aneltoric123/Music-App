//
//  StatView.swift
//  music
//
//  Created by Anel Torić on 9. 5. 2026.
//
import SwiftUI
import Foundation
import SwiftData

struct StatView: View{
    @EnvironmentObject var audioPlayer:AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    @State var timeFrame = "All"
    @State var typeStat = "Songs"
    var body: some View{
       
            VStack(spacing:10){
                TypeStat(typeStat: $typeStat)
                TimeFrame(timeFrame: $timeFrame)
                if(typeStat == "Artists"){
                    FavouriteArtists(currentUser: authManager.currentUser!,timeFrame: $timeFrame)
                }
                
                else{
                    FavouriteSongs(username: authManager.currentUser!.username,timeFrame:$timeFrame).background(.clear)
                }
            }
        
        .onAppear{
            audioPlayer.isShowingMiniPlayer = false
            audioPlayer.isShowingMiniPlayerBottom = true
        }.background(LinearGradient(
            colors: [
                .indigo,.purple
            ],
            startPoint: .top,
            endPoint: .bottom
        ))
       
    }
}
    

struct FavouriteSongs:View {
    @EnvironmentObject var authManager:AuthManager
    @EnvironmentObject var audioPlayer:AudioPlayerManager
    let username:String
    @Binding var timeFrame:String
    @Query var userPlayHistory:[PlayHistory]
    init(username:String,timeFrame: Binding<String>){
        self.username = username
        self._timeFrame = timeFrame
        
        let username = username
        _userPlayHistory =  Query(filter: #Predicate<PlayHistory>{history in
            history.user?.username == username
        },
                                  sort: \PlayHistory.song?.title
        )
    }
    var filteredHistory:[PlayHistory]{
        if timeFrame == "All"{
            return userPlayHistory
        }
        
        return userPlayHistory.filter{history in
            history.playedAt >= startDate(for: timeFrame)
            
        }
    }
    var songPlayCounts:[(song:Song,count:Int)] {
        let grouped = Dictionary(grouping: filteredHistory){history in
            history.song
        }
        return grouped.compactMap{key,value in
            guard let song = key else {return nil}
            return (song,value.count)
            
        }
        .sorted{$0.count > $1.count}
    }
    var body: some View {
        ScrollView {

            LazyVStack(spacing: 16) {

                ForEach(songPlayCounts, id: \.song.id) { item in

                    HStack {

                        SongStatView(song: item.song)

                        Spacer()

                        Text("\(item.count)")
                            .foregroundStyle(.primary)
                            .font(.headline)
                    }
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
        }
            
        }
    
    private func formatArtists(_ artists: [Artist]) -> String {
        artists.map { $0.name }.joined(separator: ", ")
    }
    func startDate(for timeFrame:String)-> Date{
        let calendar = Calendar.current
        switch timeFrame {
        case "24H":
            return calendar.date(byAdding: .hour, value: -24, to: Date())!
        case "7D":
            return calendar.date(byAdding: .day, value: -7, to: Date())!
        case "30D":
            return calendar.date(byAdding: .day, value: -30, to: Date())!
        default:
            return Date.distantPast
        }
    }
}
struct ArtistStatView: View {
    var artist:Artist
    var body: some View {
            HStack(spacing:10){
                Image(artist.songs.first!.coverpath).resizable().scaledToFit().frame(width:100,height:100).cornerRadius(100)
                
                VStack(alignment: .leading){
                    Text(artist.name) .foregroundColor(.white).lineLimit(1).truncationMode(.tail).font(.title).frame(maxWidth: 200,alignment: .leading)
                }
            }
        
    }
}
struct SongStatView:View {
    var song:Song
    var body: some View {
        HStack(spacing:10){
            Image(song.coverpath).resizable().scaledToFit().frame(width:100,height:100).cornerRadius(100)
            VStack(alignment:.leading, spacing:10){
                Text(song.title).foregroundColor(.white).lineLimit(1).truncationMode(.tail).font(.headline).frame(maxWidth: 200,alignment: .leading)
                Text(formatArtists(song.artists)).foregroundColor(.orange).lineLimit(1).truncationMode(.tail).font(.subheadline).frame(maxWidth: 200,alignment: .leading)
            }
        }
    }
    private func formatArtists(_ artists: [Artist]) -> String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}

struct FavouriteArtists: View {
    @EnvironmentObject var authManager:AuthManager
    @EnvironmentObject var audioPlayer:AudioPlayerManager
    var currentUser: User
    @Binding var timeFrame:String
    var username:String
    
    @Query var userPlayHistory:[PlayHistory]
    init(currentUser:User,timeFrame: Binding<String>){
        self.currentUser = currentUser
        self.username = currentUser.username
        self._timeFrame = timeFrame
        _userPlayHistory =  Query(filter: #Predicate<PlayHistory>{history in
            history.user?.username == username
         },
        sort: \PlayHistory.song?.title
        )
    
    }
    
    var filteredHistory:[PlayHistory]{
        if timeFrame == "All"{
            return userPlayHistory
        }
        
        return userPlayHistory.filter{history in
            history.playedAt >= startDate(for: timeFrame)
            
        }
    }
    var songPlayCounts:[(artist:Artist,count:Int)] {
        let allArtists = filteredHistory.flatMap { history in
                history.song?.artists ?? []
            }
        let grouped = Dictionary(grouping: allArtists) { artist in
               artist
            }
        return grouped.map { artist, plays in
               (artist: artist, count: plays.count)
           }
        .sorted{$0.count > $1.count}
    }
    
   
    
    var body: some View {
        
        ScrollView {

            LazyVStack(spacing: 16) {

                ForEach(songPlayCounts, id: \.artist.id) { item in

                    HStack {

                        ArtistStatView(artist: item.artist)

                        Spacer()

                        Text("\(item.count)")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
        }
    }
    private func formatArtists(_ artists: [Artist]) -> String {
        artists.map { $0.name }.joined(separator: ", ")
    }
    func startDate(for timeFrame:String)-> Date{
        let calendar = Calendar.current
        switch timeFrame {
        case "24H":
            return calendar.date(byAdding: .hour, value: -24, to: Date())!
        case "7D":
            return calendar.date(byAdding: .day, value: -7, to: Date())!
        case "30D":
            return calendar.date(byAdding: .day, value: -30, to: Date())!
        default:
            return Date.distantPast
        }
    }
}
struct TypeStat:View {
    @Binding var typeStat:String
    var body: some View {
        HStack(spacing:8){
            Button{
                typeStat = "Songs"
            }
            label:{
                Text("Songs")
                    .font(.title3)
                    .frame(height: 40)
                    .frame(width: 100)
                    .background(
                        Group {
                            if typeStat == "Songs" {
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(typeStat == "Songs" ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(typeStat == "Songs" ? .blue : .gray, lineWidth: 2)
                    )
            }.buttonStyle(.plain)
            Button{
                typeStat = "Artists"
            }
            label:{
                Text("Artists")
                    .font(.title3)
                    .frame(height: 40)
                    .frame(width: 100)
                    .background(
                        Group {
                            if typeStat == "Artists" {
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(typeStat == "Artists" ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(typeStat == "Artists" ? .blue : .gray, lineWidth: 2)
                    )
            }.buttonStyle(.plain)
        }.padding()
    }
}
struct TimeFrame:View {
    @Binding var timeFrame:String
    var body: some View {
        HStack(spacing:8){
            Button{
                timeFrame = "24H"
            }
            label:{
                Text("24H")
                    .font(.title3)
                    .frame(height: 40)
                    .frame(width: 60)
                    .background(
                        Group {
                            if timeFrame == "24H" {
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(timeFrame == "24H" ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(timeFrame == "24H" ? .green : .gray, lineWidth: 2)
                    )
            }.buttonStyle(.plain)
            
            
            Button{
                timeFrame = "7D"
            }
            label:{
                Text("7D")
                    .font(.title3)
                    .frame(height: 40)
                    .frame(minWidth: 60)
                    .background(
                        Group {
                            if timeFrame == "7D" {
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(timeFrame == "7D" ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(timeFrame == "7D" ? .green : .gray, lineWidth: 2)
                    )
            }.buttonStyle(.plain)
            
            Button{
                timeFrame = "30D"
            }
            label:{
                Text("30D")
                    .font(.title3)
                    .frame(height: 40)
                    .frame(minWidth: 60)
                    .background(
                        Group {
                            if timeFrame == "30D" {
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(timeFrame == "30D" ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(timeFrame == "30D" ? .green : .gray, lineWidth: 2)
                    )
            }.buttonStyle(.plain)
            
            Button{
                timeFrame = "All"
            }
            label:{
                Text("All")
                    .font(.title3)
                    .frame(height: 40)
                    .frame(minWidth: 60)
                    .background(
                        Group {
                            if timeFrame == "All" {
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(timeFrame == "All" ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(timeFrame == "All" ? .green : .gray, lineWidth: 2)
                    )
            }.buttonStyle(.plain)
            
        }.padding()
    }
}


