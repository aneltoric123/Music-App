//
//  AlbumSearchHistory.swift
//  music
//
//  Created by Anel Torić on 7. 8. 2026.
//

//
//  ArtistSearchHistory.swift
//  music
//
//  Created by Anel Torić on 11. 3. 26.
//

import Foundation
import SwiftData

@Model
final class AlbumSearchHistory {
    var id: UUID = UUID()
    @Relationship var album: Album
    var date: Date = Date()
    @Relationship var user: User
    init(album: Album,user:User) {
        self.album = album
        self.user = user
    }
}
