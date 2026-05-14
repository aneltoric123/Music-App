import AVFoundation
import SwiftData
import SwiftUI
import MediaPlayer
internal import Combine
import MediaPlayer
class AudioPlayerManager: ObservableObject {
    
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var isShowingMiniPlayer = true
    @Published var isShowingMiniPlayerBottom = false
    @Published var totalDuration: TimeInterval = 0
    weak var authManager:AuthManager?
    var nowPlayingInfo: [String: Any] = [:]
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?
    
    var context: ModelContext
    
    var playlist: [Song] = []
    var playlistTitle:String = ""
    var currentIndex: Int = 0
    var isPlaylistShuffled: Bool = false
    
   
    init(context: ModelContext) {
        self.context = context
        setupRemoteControls()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default
            )

            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }
    func playSong(
        _ song: Song,
        from playlist: [Song],
        playlistName: String = "",
        artist: Artist? = nil,
        isOnlySong: Bool,
        songIndex: Int = 0,
        shuffle: Bool = false,
        preserveIndex: Bool = false
    ) {
        recordPlay(for:song)
        configurePlaylist(
            song: song,
            playlist: playlist,
            playlistName: playlistName,
            artist: artist,
            isOnlySong: isOnlySong,
            songIndex: songIndex,
            shuffle: shuffle,
            preserveIndex: preserveIndex
        )
        
        startPlayback(song: song)
       
       
    }
    
    func setupNowPlaying() {
        guard let song = currentSong,
              let player = player else { return }
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = formatArtists(song.artists)
        
        if let image = UIImage(named: song.coverpath) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        let duration = player.currentItem?.asset.duration.seconds ?? 0

        if duration.isFinite {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }

            self.player?.play()
            self.isPlaying = true

            self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo

            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }

            self.player?.pause()
            self.isPlaying = false

            self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo

            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
    }
    private func recordPlay(for song:Song){
        guard let user = authManager?.currentUser else { return }
        let event = PlayHistory(completed: false, user:user,song:song)
        context.insert(event)
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func configurePlaylist(
        song: Song,
        playlist: [Song],
        playlistName:String,
        artist: Artist?,
        isOnlySong: Bool,
        songIndex: Int,
        shuffle: Bool,
        preserveIndex: Bool
    ) {
        guard let user = authManager?.currentUser else { return }
        let blockedSongs = user.blockedSongs
        let blockedArtists = user.blockedArtists
        if isOnlySong && artist == nil {
            self.playlist = [song]
           
            _ = song.genre
            
            let currentID = song.id

            let fetch = FetchDescriptor<Song>(
                predicate: #Predicate<Song> {
                    $0.id != currentID
                }
            )
            if let allSongs = try? context.fetch(fetch) {

                let blockedSongIDs = Set(blockedSongs.map(\.id))
                let blockedArtistIDs = Set(blockedArtists.map(\.id))

                let filtered = allSongs.filter { song in
                    !blockedSongIDs.contains(song.id) &&
                    !song.artists.contains {
                        blockedArtistIDs.contains($0.id)
                    }
                }

                self.playlist += Array(filtered.shuffled().prefix(200))
                currentIndex = 0
            }
        }
        else if  isOnlySong, let artist = artist {
            self.playlist = [song]
            let currentID = song.id
            
            let fetch = FetchDescriptor<Song>(
                predicate: #Predicate<Song> {
                    $0.id != currentID
                }
            )

            if let allSongs = try? context.fetch(fetch) {

                let blockedSongIDs = Set(blockedSongs.map(\.id))
                let blockedArtistIDs = Set(blockedArtists.map(\.id))

                let filtered = allSongs.filter { s in
                    s.artists.contains(artist) &&
                    !blockedSongIDs.contains(s.id) &&
                    !s.artists.contains {
                        blockedArtistIDs.contains($0.id)
                    }
                }

                self.playlist += filtered.shuffled()
                currentIndex = 0
            }
        }
        else {
           
            self.playlist = playlist
            
            if shuffle {
                self.playlist = playlist.filter { $0.id != song.id }
                self.playlist.shuffle()
                self.playlist.insert(song, at: 0)
                isPlaylistShuffled = true
            } else {
                isPlaylistShuffled = false
            }
        }
        
        
        if !preserveIndex {
            if shuffle {
                currentIndex = 0
            } else {
                currentIndex = songIndex
            }
        }
        self.playlistTitle = playlistName
        currentSong = song
        
    }
    private func setupEndObserver() {

        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.markCurrentSongCompleted(
                secondPlayed: self.totalDuration
            )

            self.playNext()
        }
    }
    
  
    private func startPlayback(song: Song) {

        let fileName = (song.filepath as NSString).deletingPathExtension

        guard let filePath = Bundle.main.path(
            forResource: fileName,
            ofType: "mp3"
        ) else {
            print("Could not find mp3 file")
            return
        }

        let url = URL(fileURLWithPath: filePath)

        let item = AVPlayerItem(url: url)

        if let player = player {
            player.replaceCurrentItem(with: item)
        } else {
            player = AVPlayer(playerItem: item)
        }

        removeTimeObserver()
        setupTimeObserver()
        setupEndObserver()

        player?.play()

        isPlaying = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupNowPlaying()
        }
    }
    
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        } else {
            player.play()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        isPlaying.toggle()
    }
    
    func playNext() {
        guard currentIndex + 1 < playlist.count else { return }
        
        currentIndex += 1
        
        playSong(
            playlist[currentIndex],
            from: playlist,
            playlistName: playlistTitle,
            isOnlySong: false,
            preserveIndex: true
        )
    }
    
    func playPrevious() {
        guard currentIndex > 0 else { return }
        
        currentIndex -= 1
        
        playSong(
            playlist[currentIndex],
            from: playlist,
            playlistName: playlistTitle,
            isOnlySong: false,
            preserveIndex: true
        )
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            
            self.currentTime = time.seconds
            
            let duration = player.currentItem?.duration.seconds ?? 0

            if duration.isFinite && !duration.isNaN {
                self.totalDuration = duration
                
                if time.seconds >= duration - 0.5 {
                    self.markCurrentSongCompleted(secondPlayed: duration)
                }
            }
            
            self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time.seconds
            self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? 1 : 0
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
        }
    }
    private func markCurrentSongCompleted(secondPlayed: Double){
        guard let user = authManager?.currentUser,let currentSong = currentSong else {return}
        
        let fetch = FetchDescriptor<PlayHistory>()
        if let histories = try? context.fetch(fetch),
           let latest = histories.last(where: {
               $0.user?.id == user.id &&
               $0.song?.id == currentSong.id
           }){
            latest.completed = true
            latest.secondsPlayed = secondPlayed
            try? context.save()
        }
        
    }
    
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
   
    deinit {
        removeTimeObserver()
        
        if let observer = endObserver {
                NotificationCenter.default.removeObserver(observer)
            }
    }
    func formatArtists(_ artists: [Artist]) -> String {
        var artistText: String = ""
        if(artists.count > 1){
            for artist in artists {
                artistText += artist.name + ", "
            }
            artistText.removeLast(2)
        }
        else{
            artistText = artists.first?.name ?? "Anonymous"
        }
        return artistText
        }
}
