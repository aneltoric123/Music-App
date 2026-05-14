//
//  ArtistSearchHistory.swift
//  music
//
//  Created by Anel Torić on 11. 3. 26.
//

import Foundation
import SwiftData

@Model
final class ArtistSearchHistory {
    var id: UUID = UUID()
    @Relationship var artist: Artist
    var date: Date = Date()
    @Relationship var user: User
    init(artist: Artist,user:User) {
        self.artist = artist
        self.user = user
    }
}
