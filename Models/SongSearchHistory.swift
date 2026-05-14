//
//  SongSearchHistory.swift
//  music
//
//  Created by Anel Torić on 11. 3. 26.
//

import Foundation
import SwiftData

@Model
final class SongSearchHistory {
    var id: UUID = UUID()
    @Relationship var song: Song
    var date: Date = Date()
    @Relationship var user: User
    init(song: Song,user:User) {
        self.song = song
        self.user = user
    }
}
