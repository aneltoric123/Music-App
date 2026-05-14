//
//  PlaylistCoverView.swift
//  music
//
//  Created by Anel Torić on 13. 3. 26.
//

import SwiftUI
import SwiftData
import Foundation

struct PlaylistCoverView: View {
    var playlist:Playlist
    var body: some View {
        HStack{
            ZStack(){
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.gray, .black],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)).frame(width: 100,height: 100)
                if(playlist.name == "Liked Songs"){
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.purple, .pink],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                    Image(systemName: "heart.fill").resizable().scaledToFit().frame(width:50, height:50)
                    
                }
                else{
                    VStack{
                        HStack(spacing:10){
                            var first2: [Song]{
                                Array(playlist.entries.map(\.song).prefix(2))
                            }
                            
                            ForEach(first2){ song in
                                let covername = song.coverpath
                                        Image(covername).resizable().scaledToFit().frame(width: 50, height: 50)
                                    }
                                    
                            }
                        }
                        
                        HStack(spacing:10){
                            var last2: [Song]{
                                Array(playlist.entries.map(\.song).suffix(2))
                            }
                            ForEach(last2){ song in
                                let covername = song.coverpath
                                Image(covername).resizable().scaledToFit().frame(width: 50, height: 50)
                                
                                
                            }
                        }
                    }
                    
                }
            
                NavigationLink{
                    PlaylistView(playlist: playlist)}
                label:{
                    VStack(alignment: .leading){
                        Text(playlist.name).font(.title).foregroundColor(.white).truncationMode(.tail).frame(width: 240,alignment:.leading).lineLimit(1).contentShape(Rectangle())
                        Text(String("\(playlist.entries.count) Songs")).foregroundColor(.gray).font(.subheadline).bold().truncationMode(.tail).frame(width: 240,alignment:.leading).lineLimit(1).contentShape(Rectangle())
                    }
                }
        }
    }
}
