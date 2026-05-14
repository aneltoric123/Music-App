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
    @Environment(\.modelContext) private var context
    var body: some View {
        
            VStack(spacing: 10){
                Spacer()
                let coverName = song.coverpath
               Image(coverName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                  
                VStack(spacing: 4){
                    Text(song.title)
                        .font(.subheadline).bold().foregroundColor(.white).frame(width: 100).lineLimit(1).truncationMode(.tail)
                    Text(formatArtists(song.artists))
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
