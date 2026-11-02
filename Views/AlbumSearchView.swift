//
//  AlbumSearchView.swift
//  music
//
//  Created by Anel Torić on 7. 8. 2026.
//



import SwiftUI
import Foundation
import SwiftData

struct AlbumSearchView: View {
    var album: Album
    @Query(sort: \AlbumSearchHistory.date, order: .reverse)
    private var searches: [AlbumSearchHistory]
    @EnvironmentObject var auth:AuthManager
    var user:User{
        auth.currentUser!
    }
    @Environment(\.modelContext)  var context

    var body: some View {
        VStack(alignment: .leading){
            HStack {
                if(album.songs.count > 0){
                    
                    var parsedComponets:[Substring] {album.songs.first!.title.split(separator: " - ")}
                    var displayName: String{
                        parsedComponets[0] + " - "  + parsedComponets[1]
                    }
                    AsyncCover(song: album.songs.first!, size: 63)
                    
                        
                    VStack(alignment: .leading){
                        Text(album.name).foregroundColor(.white).font(.headline).fontWeight(.regular).truncationMode(.tail).lineLimit(1)
                        Text("Album" + " ݁ ⋅ " + formatArtists(album.artists))
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .truncationMode(.tail).lineLimit(1)
                            .fontWeight(.semibold)
                        
                    }
                    Spacer()
                }
            }.padding(.bottom,10).padding(.horizontal)
            
        }
    }
            
    func formatArtists(_ artists:[Artist]) -> String{
        return artists.map{ $0.name }.joined(separator: ", ")
    }
    func performSearchAlbum(album:Album){
       
        if let exists = searches.first(where: { $0.album == album}){
            context.delete(exists)
        }
        user.albumSearchHisotry.append(AlbumSearchHistory(album: album,user: user))
        do{
            try context.save()
        } catch{
            print("Failed to save \(error)")
        }
    }
        

    }
