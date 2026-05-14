import SwiftData
import Foundation

func getLikedSongs(playlist:Playlist)->[Song]{
        return  playlist.entries.map(\.song)
    }

