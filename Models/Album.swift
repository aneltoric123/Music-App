import Foundation
import SwiftData

@Model
final class Album {
    @Attribute(.unique) var id_album: Int
    var name: String

    @Relationship(inverse: \Song.album)
    var songs: [Song] = []

    var artists: [Artist] = []
    init(id: Int, name: String) {
        self.id_album = id
        self.name = name
    }
}
