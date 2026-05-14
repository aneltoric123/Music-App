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
        VStack{
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
            
            List{
                if isSearching{
                    Section {
                        ForEach(searchResultsPlaylist){ playlist in PlaylistCoverView(playlist: playlist) .navigationLinkIndicatorVisibility(.hidden)
                            
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
                
            }.onAppear{
                isFocused = true
                    
                audioManager.isShowingMiniPlayer = false
                audioManager.isShowingMiniPlayerBottom = true
                    
            }.listStyle(.plain)
        }
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
