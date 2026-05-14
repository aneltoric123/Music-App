//
//  UserData.swift
//  music
//
//  Created by Anel Torić on 25. 4. 2026.
//

import Foundation
import SwiftData

@Model

final class PlayHistory{
    
    @Attribute(.unique) var id : UUID
    var playedAt = Date()
    var secondsPlayed:Double
    var completed: Bool
    @Relationship var user: User?
    @Relationship var song: Song?
    
    init(id: UUID = UUID(), playedAt: Date = .now, secondsPlayed: Double = 0, completed: Bool = false, user: User? = nil, song: Song? = nil) {
        self.id = id
        self.playedAt = playedAt
        self.secondsPlayed = secondsPlayed
        self.completed = completed
        self.user = user
        self.song = song
    }
    
    
}
