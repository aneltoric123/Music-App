//
//  SearchBar.swift
//  music
//
//  Created by Anel Torić on 27. 2. 26.
//

import Foundation
import SwiftData

@Model
final class SearchHistory {

    var id: UUID = UUID()
    var text: String
    var date: Date = Date()
    @Relationship var user:User
    init(text: String,user:User) {
        self.text = text
        self.user = user
    }
}
