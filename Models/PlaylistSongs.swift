//
//  PlaylistSongs.swift
//  music
//
//  Created by Anel Torić on 26. 4. 2026.
//

import SwiftData
import Foundation

@Model
final class PlaylistSongs{
    var playlistSongs_id: UUID
    @Relationship var playlist: Playlist
    @Relationship var song: Song
    var order:Int
    var timeAdded: Date
    init(playlistSongs_id: UUID = UUID(),order:Int, playlist: Playlist, song: Song, timeAdded: Date = .now) {
        self.playlistSongs_id = playlistSongs_id
        self.playlist = playlist
        self.song = song
        self.order = order
        self.timeAdded = timeAdded
    }
    
    
}
