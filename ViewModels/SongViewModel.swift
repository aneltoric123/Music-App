//
//  SongViewModel.swift
//  music
//
//  Created by Anel Torić on 2. 3. 26.
//
import SwiftUI
import Foundation
import SwiftData
import Observation
internal import Combine

@MainActor

class SongViewModel: ObservableObject {
    
    @Published var songs: [Song] = []
    private let modelContext: ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    func fetchSongs() {
        do {
            let descriptor = FetchDescriptor<Song>()
            let fetchedSongs = try modelContext.fetch(descriptor)

            if fetchedSongs.isEmpty {
                print("Database empty. Importing JSON...")
                importData(context: modelContext)

                let newSongs = try modelContext.fetch(descriptor)
                songs = newSongs
            } else {
                songs = fetchedSongs
            }

            print("Fetched songs: \(songs.count)")
        } catch {
            print("Error fetching songs: \(error)")
        }
    }
}


