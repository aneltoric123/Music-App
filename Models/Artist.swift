import Foundation
import SwiftData

@Model
final class Artist {
    @Attribute(.unique) var id: Int
    var name: String

    @Relationship(inverse: \Song.artists)
    var songs: [Song] = []

    @Relationship(inverse: \Album.artists)
    var albums: [Album] = []

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
