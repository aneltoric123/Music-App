//
//  playlist.swift
//  music
//
//  Created by Anel Torić on 25. 2. 26.
//

import Foundation
import SwiftUI
import SwiftData


@Model
final class Playlist {
    var id_playlist: UUID
    var name: String

    @Relationship(deleteRule: .cascade)
    @Relationship(inverse: \PlaylistSongs.playlist)
    var entries: [PlaylistSongs] = []
    var shuffle:Bool = false
    @Relationship
    var owner: User?

    init(
      id_playlist: UUID = UUID(),
      name: String,
      owner: User
    ) {
        self.id_playlist = id_playlist
        self.name = name
        self.owner = owner
    }
}

