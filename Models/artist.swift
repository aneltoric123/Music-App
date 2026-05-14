//
//  artist.swift
//  music
//
//  Created by Anel Torić on 25. 2. 26.
//

import Foundation
import SwiftData

@Model

final class Artist{
    @Attribute(.unique) var id: UUID
    @Attribute var name: String
    var songs: [Song]
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.songs = []
    }
}
