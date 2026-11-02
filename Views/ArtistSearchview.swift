//
//  ArtistSearchview.swift
//  music
//
//  Created by Anel Torić on 11. 3. 26.
//

import SwiftUI
import Foundation
import SwiftData

struct ArtistSearchView: View {
    var artist: Artist
    @Query(sort: \ArtistSearchHistory.date, order: .reverse)
    private var searches: [ArtistSearchHistory]
    @EnvironmentObject var auth: AuthManager
    @Environment(\.modelContext) var context
    
    var user: User {
        auth.currentUser!
    }
    
    @Query private var latestSongsByArtist: [Song]
    
    init(artist: Artist) {
        self.artist = artist
        let artistID = artist.id
        self._latestSongsByArtist = Query(
            filter: #Predicate<Song> { song in
                song.artists.contains(where: { $0.id == artistID })
            },
            sort: \Song.persistentModelID,
            order: .reverse
        )
    }
    
    var representativeSong: Song? {
        let match = latestSongsByArtist.first(where: { $0.artists.contains(where: { $0.id == artist.id }) })
        return match ?? latestSongsByArtist.first
    }
    
    var displayName: String {
        guard let song = representativeSong else { return "" }
        let components = song.title.split(separator: " - ")
        if components.count >= 2 {
            return "\(components[0]) - \(components[1])"
        }
        return song.title
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                
                
                if let _ = representativeSong {
                    
                    AsyncCover(song: representativeSong!, size: 63)
                            
                        
                        if user.blockedArtists.contains(where: { $0.id == artist.id }) {
                            Image(systemName: "slash.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                    
                }
                else{
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 63, height: 63).cornerRadius(5)
                        .opacity(representativeSong != nil ? 0 : 1)
                }
                VStack(alignment: .leading){
                    Text(artist.name)
                        .foregroundColor(.white)
                        .font(.headline)
                        .truncationMode(.tail).lineLimit(1)
                        .fontWeight(.regular)
                    Text("Artist").font(.subheadline).fontWeight(.regular).foregroundColor(.gray)
                }
                Spacer()
                
                
                Menu {
                    if !user.followedArtists.contains(where: { $0.id == artist.id }) {
                        Button("Follow artist", systemImage: "person.fill.checkmark", action: followArtist)
                    } else {
                        Button("Unfollow artist", systemImage: "person.fill.xmark", action: unfollowArtist)
                    }
                    
                    if !user.blockedArtists.contains(where: { $0.id == artist.id }) {
                        Button("Block artist", systemImage: "person.slash.fill", action: blockArtist)
                    } else {
                        Button("Unblock artist", systemImage: "person.circle.fill", action: unblockArtist)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
        }.padding(.bottom, 10)
            .padding(.horizontal)
    }
    
    func blockArtist() {
        user.blockedArtists.append(artist)
        user.followedArtists.removeAll { $0.id == artist.id }
        
        let descriptor = FetchDescriptor<Playlist>()
        if let playlists = try? context.fetch(descriptor) {
            for playlist in playlists {
                playlist.entries.removeAll { entry in
                    entry.song.artists.contains(where: { $0.id == artist.id })
                }
            }
        }
        try? context.save()
    }
    
    func followArtist() {
        user.followedArtists.append(artist)
        user.blockedArtists.removeAll { $0.id == artist.id }
        try? context.save()
    }
    
    func unblockArtist() {
        user.blockedArtists.removeAll { $0.id == artist.id }
        try? context.save()
    }
    
    func unfollowArtist() {
        user.followedArtists.removeAll { $0.id == artist.id }
        try? context.save()
    }
    
    func performSearchArtist(artist: Artist) {
        if let exists = searches.first(where: { $0.artist == artist }) {
            context.delete(exists)
        }
        user.artistSearchHistory.append(ArtistSearchHistory(artist: artist, user: user))
        do {
            try context.save()
        } catch {
            print("Failed to save \(error)")
        }
    }
}
