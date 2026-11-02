//
//  SongCoverView.swift
//  music
//
//  Created by Anel Torić on 5. 3. 26.
//

import SwiftUI
import Foundation
import SwiftData


struct SongCoverView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    var song: Song
    var parsedComponets: [Substring] { song.title.split(separator: " - ")}
    var displayName: String{
        parsedComponets[0] + " - "  + parsedComponets[1]
    }
    @Environment(\.modelContext) private var context
    var body: some View {
        
            VStack(spacing: 10){
                Spacer()
              
                
                if let url = resolveCoverURL(for: song){
                    AsyncCover(song: song, size: 52)
                                   
                                } else {
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 52, height: 52)
                                        .foregroundColor(.gray)
                                }
                            
                            
                  
                VStack(spacing: 4){
                    Text(parsedComponets[0])
                        .font(.subheadline).bold().foregroundColor(.white).frame(width: 100).lineLimit(1).truncationMode(.tail)
                    Text(parsedComponets[1])
                        .foregroundColor(.gray).frame(width: 100).lineLimit(1).truncationMode(.tail)
                }
            }.buttonStyle(.plain)
        }
    
    
    func formatArtists(_ artists: [Artist]) -> String {
        var artistText: String = ""
        for artist in artists {
            artistText += artist.name + ", "
        }
        if !artistText.isEmpty{
            artistText.removeLast(2)
            return artistText
        }
        else{
            return ""
        }
        }
}
