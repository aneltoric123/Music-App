//
//  song_artist.swift
//  music
//
//  Created by Anel Torić on 25. 2. 26.
//

import Foundation
import SwiftData

@Model

final class Song_Artist{
    @Relationship var song_id: UUID
    @Relationship var artist_id : UUID
    init(song_id: UUID, artist_id: UUID) {
        self.song_id = song_id
        self.artist_id = artist_id
    }
}
