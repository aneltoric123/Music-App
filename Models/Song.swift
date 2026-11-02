//
//  song.swift
//  music
//
//  Created by Anel Torić on 25. 2. 26.
//
import Foundation
import SwiftData

@Model
final class Song:Hashable {
    @Attribute(.unique) var id_song: Int
    var title: String
    var filepath: String
    var genre: Genre?
    var album: Album?
    static func == (lhs: Song, rhs: Song) -> Bool {
            lhs.id_song == rhs.id_song
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    var artists: [Artist] = []
    var primaryArtistId: Int?
    init(id: Int,title: String,filepath:String) {
        self.id_song = id
        self.title = title
        self.filepath = filepath
    }

    func addArtist(_ artist: Artist) {
        if !artists.contains(where: { $0.id == artist.id }) {
            artists.append(artist)
        }
    }
}



