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
    var id_genre: Int
    var name: String
    @Relationship var songs: [Song]
    init(id: Int, name: String) {
        self.id_genre = id
        self.name = name
        self.songs = []
    }
}
