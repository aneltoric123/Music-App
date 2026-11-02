//
//  LibrarySearchView.swift
//  music
//
//  Created by Anel Torić on 13. 3. 26.
//

import SwiftUI
import SwiftData
import Foundation

struct LibrarySearchView: View {
    @EnvironmentObject var audioManager:AudioPlayerManager
    @State private var isSearching: Bool = false
    @State private var searchText = ""
    @State private var searchResultsArtists: [Artist] = []
    @State private var searchResultsPlaylist: [Playlist] = []
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    @FocusState private var isFocused : Bool
    var body: some View {
        ZStack(alignment: .top){
            ZStack {
                LinearGradient(
                    colors: [
                        .black,
                        Color(red: 0.08, green: 0.05, blue: 0.15),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Circle()
                    .fill(.purple.opacity(0.25))
                    .frame(width: 300)
                    .blur(radius: 100)
                    .offset(x: -120, y: -250)
                
                Circle()
                    .fill(.cyan.opacity(0.18))
                    .frame(width: 250)
                    .blur(radius: 100)
                    .offset(x: 140, y: 250)
            }
            VStack(alignment: .leading){
                
                HStack{
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search your playlists and followed artists!",text: $searchText).focused($isFocused).submitLabel(.search).autocorrectionDisabled(true).textInputAutocapitalization(.never).onChange(of: searchText){
                        oldValue,newValue in updateSearchResults()
                    }
                    
                    
                    if !searchText.isEmpty{
                        Button{
                            withAnimation{
                                searchText = ""
                                isFocused = false
                                isSearching = false
                                searchResultsArtists = []
                                searchResultsPlaylist = []
                                
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    } else{
                        Button("Cancel") {isFocused = false}.foregroundColor(.accentColor)
                    }
                }.padding(8).background(Color(.systemGray6)).cornerRadius(8).padding(.horizontal).padding(.vertical,8)
                
                ScrollView{
                    if isSearching{
                        Section {
                            ForEach(searchResultsPlaylist){ playlist in PlaylistSearchView(playlist: playlist) .navigationLinkIndicatorVisibility(.hidden)
                                
                            }
                            ForEach(searchResultsArtists){artist in ArtistSearchLibraryView(artist: artist)} .navigationLinkIndicatorVisibility(.hidden)
                        }
                        header: {
                            if(searchResultsPlaylist.count + searchResultsArtists.count == 0){
                                Text("No results for \(searchText)")
                            }
                            else if(searchResultsPlaylist.count + searchResultsArtists.count == 1){
                                Text("1 Result for \(searchText)")
                            }
                            else{
                                Text("\(searchResultsPlaylist.count + searchResultsArtists.count) Results for \(searchText)")
                            }
                        }
                        
                    }
                }.scrollIndicators(.hidden)
                    
                
            }.onAppear{
                isFocused = true
                
                audioManager.isShowingMiniPlayer = false
                audioManager.isShowingMiniPlayerBottom = true
                
            }
        }.padding(.bottom,audioManager.currentSong != nil ? 120 : 10)
    }
    
     func updateSearchResults(){
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSearching = !trimmed.isEmpty
        if isSearching{
            let playDesc = FetchDescriptor<Playlist>(predicate: #Predicate<Playlist>{playlist in playlist.name.localizedStandardContains(trimmed)
                
            })
            let artDesc = FetchDescriptor<Artist>(predicate: #Predicate<Artist>{artist in artist.name.localizedStandardContains(trimmed)
            })
            let searchResultsPlaylistAll = (try? context.fetch(playDesc)) ?? []
            let searchResultsArtistsAll = (try? context.fetch(artDesc)) ?? []
            searchResultsPlaylist = searchResultsPlaylistAll.filter{
                authManager.currentUser == $0.owner
            }
            searchResultsArtists = searchResultsArtistsAll.filter{
                authManager.currentUser!.followedArtists.contains($0)
            }
        }
        else{
            searchResultsArtists = []
            searchResultsPlaylist = []
        }
    }
}
struct PlaylistSearchView : View {
    var playlist:Playlist
    @EnvironmentObject var audioManager:AudioPlayerManager
    @EnvironmentObject var authManager:AuthManager
    @Environment(\.modelContext) private var context
    var body: some View {
        NavigationLink(destination: PlaylistView(playlist: playlist)){
            HStack{
                
                VStack(alignment: .leading, spacing: 0){
                    HStack(spacing:0){
                        var first2: [Song]{
                            Array(playlist.entries.map(\.song).prefix(2))
                        }
                        
                        ForEach(first2){ song in
                            var parsedComponets: [Substring] { song.title.split(separator: " - ")}
                            var displayName: String{
                                parsedComponets[0] + " - "  + parsedComponets[1]
                            }
                            
                            AsyncCover(song: song, size: 60)
                        }
                        
                    }
                    
                    
                    HStack(spacing:0){
                        var last2: [Song]{
                            Array(playlist.entries.map(\.song).suffix(2))
                        }
                        ForEach(last2){ song in
                            var parsedComponets: [Substring] { song.title.split(separator: " - ")}
                            var displayName: String{
                                parsedComponets[0] + " - "  + parsedComponets[1]
                            }
                            
                            AsyncCover(song: song, size: 60)
                            
                            
                        }
                    }
                }
                
                VStack(alignment: .leading){
                    Text(playlist.name).font(.title).foregroundColor(.white).truncationMode(.tail).frame(width: 240,alignment:.leading).lineLimit(1).contentShape(Rectangle())
                    
                    Text("Playlist ⋅ " +  String("\(playlist.entries.count) Songs")).foregroundColor(.gray).font(.subheadline).bold().truncationMode(.tail).frame(width: 240,alignment:.leading).lineLimit(1).contentShape(Rectangle())
                }
                
                
            }.padding(.horizontal,20)
        }.navigationLinkIndicatorVisibility(.hidden)

    }
}
