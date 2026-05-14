import SwiftData
import Foundation

@Observable
class LikedSongsPlaylist {

    let context: ModelContext
    let authManager: AuthManager

    init(
        context: ModelContext,
        authManager: AuthManager
    ) {
        self.context = context
        self.authManager = authManager
    }
    var likedSongs:[Song] = []

    func getLikesPlaylist() -> Playlist? {
        guard let currentUser = authManager.currentUser else {
            return nil
        }

        let descriptor = FetchDescriptor<Playlist>(
            predicate: #Predicate {
                $0.name == "Liked Songs"
            }
        )

        do {
            return try context.fetch(descriptor)
                .first(where: { $0.owner?.id == currentUser.id })
        } catch {
            print("Failed fetching liked songs playlist:", error)
            return nil
        }
    }

func getLikedSongs(playlist:Playlist)->[Song]{
        return  playlist.entries.map(\.song)
    }
}
