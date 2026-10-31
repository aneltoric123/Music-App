//
//  genre.swift
//  music
//
//  Created by Anel Torić on 25. 2. 26.
//

import Foundation
import SwiftData


@Model

final class Genre {
    var id: UUID
    var name: String
    @Relationship var songs: [Song]
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.songs = []
    }
}
