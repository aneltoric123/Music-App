//
//  SearchBar.swift
//  music
//
//  Created by Anel Torić on 27. 2. 26.
//

import Foundation
import SwiftData

@Model
class SearchHistory {

    var id: UUID = UUID()
    var text: String
    var date: Date = Date()
    init(text: String) {
        self.text = text
    }
}
