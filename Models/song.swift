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
    @Attribute(.unique) var id: UUID
    var dateAdded =  Date()
    var title: String
    var filepath: String
    var coverpath: String
    var genre: Genre?
    static func == (lhs: Song, rhs: Song) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    @Relationship(inverse: \Artist.songs)
    var artists: [Artist] = []

    init(id: UUID = UUID(), dateAdded:Date = .now,title: String, filepath: String, coverpath: String) {
        self.id = id
        self.dateAdded = dateAdded
        self.title = title
        self.filepath = filepath
        self.coverpath = coverpath
    }

    func addArtist(_ artist: Artist) {
        if !artists.contains(where: { $0.id == artist.id }) {
            artists.append(artist)
        }
    }
}



