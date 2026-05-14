//
//  Playlist+Songs.swift
//  music
//
//  Created by Anel Torić on 29. 4. 2026.
//

import SwiftData

extension Playlist {

    var songs: [Song] {
        entries.map(\.song)
    }

}
