//
//  User.swift
//  music
//
//  Created by Anel Torić on 25. 4. 2026.
//

import Foundation
import SwiftData

@Model

final class User{
    @Attribute(.unique) var id: UUID
    @Attribute var username: String
    @Attribute var password: String
    @Attribute var salt: String
    @Relationship var blockedSongs: [Song] = []
    @Relationship var blockedArtists: [Artist] = []
    @Relationship var followedArtists: [Artist] = []
    @Relationship var playlists: [Playlist] = []
    @Relationship(deleteRule: .cascade, inverse: \SearchHistory.user)
    @Relationship var searchHistory: [SearchHistory] = []
    @Relationship(deleteRule: .cascade, inverse: \SongSearchHistory.user)
    @Relationship var songSearchHistory: [SongSearchHistory] = []
    @Relationship(deleteRule: .cascade, inverse: \ArtistSearchHistory.user)
    var artistSearchHistory: [ArtistSearchHistory] = []
    @Relationship var PlayHistory: [PlayHistory] = []
    init(id: UUID = UUID(), username: String,password:String,salt:String) {
        self.id = id
        self.username = username
        self.password = password
        self.salt = salt
       
    }
}
