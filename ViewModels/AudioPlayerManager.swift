import AVFoundation
import SwiftData
import SwiftUI
import MediaPlayer
internal import Combine

class AudioPlayerManager: ObservableObject {
    private struct QueueSnapshot: Codable{
        var currentSong:Int?
        var playlist: [Int]
        var playlistTitle: String
        var currentIndex: Int
        var showMiniPlayer:Bool
        var showingMiniPlayerBottom:Bool
        var currentTime:TimeInterval
    }
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var isShowingMiniPlayer = true
    @Published var isShowingMiniPlayerBottom = false
    @Published var totalDuration: TimeInterval = 0
    weak var authManager: AuthManager?
    var nowPlayingInfo: [String: Any] = [:]
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?
    var isStored:Bool = false
    var context: ModelContext
    var parsedComponents: [Substring] {
        guard let song = currentSong else { return [] }
        return song.title.split(separator: " - ")
    }
    var displayName: String {
        let components = parsedComponents
        guard components.count >= 2 else {
            return currentSong?.title ?? ""
        }
        return "\(components[0]) - \(components[1])"
    }
    var playlist: [Song] = []
    var playlistTitle: String = ""
    var currentIndex: Int = 0
    var isPlaylistShuffled: Bool = false
    private static let queueKey = "saveQueue"
    private var saveTask: Task<Void, Never>?
    private var isRestoring = false
    init(context: ModelContext) {
        self.context = context
        setupRemoteControls()
        configureAudioSession()
    }
    private func snapShot() -> QueueSnapshot{
        
            QueueSnapshot(currentSong: currentSong!.id_song, playlist: playlist.map(\.id_song), playlistTitle: playlistTitle, currentIndex: currentIndex, showMiniPlayer: isShowingMiniPlayer, showingMiniPlayerBottom: isShowingMiniPlayerBottom, currentTime: currentTime)
        
        
        
    }
    func saveNow(){
        saveTask?.cancel()
        guard let data = try? JSONEncoder().encode(snapShot()) else { return }
        UserDefaults.standard.set(data, forKey: Self.queueKey)
    }
    private func scheduleSave(){
        guard !isRestoring else {return}
        saveTask?.cancel()
        if (isPlaying){
            isPlaying.toggle()
            togglePlayPause()
        }
        
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(5000))
            guard !Task.isCancelled,let self ,!self.isRestoring else { return }
            self.saveNow()
            
        }
    }
    func restoreQueueIfNeeded() {
        
        guard currentSong == nil,
              let data = UserDefaults.standard.data(forKey: Self.queueKey),
              let snap = try? JSONDecoder().decode(QueueSnapshot.self, from: data),
              let firstID = snap.currentSong else { return }

        isRestoring = true
        defer { isRestoring = false }

        let ids = Set(snap.playlist)
        let fetched = (try? context.fetch(
            FetchDescriptor<Song>(predicate: #Predicate { ids.contains($0.id_song) })
        )) ?? []
        let byID = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id_song, $0) })
        let ordered = snap.playlist.compactMap { byID[$0] }
        guard !ordered.isEmpty else { return }

        playlist = ordered
        playlistTitle = snap.playlistTitle
        currentIndex = snap.currentIndex
        
        isShowingMiniPlayer = snap.showMiniPlayer
        isShowingMiniPlayerBottom = snap.showingMiniPlayerBottom

        if let song = byID[firstID] {
            
            currentSong = song
            configureAudioSession()
            setupNowPlaying()
            setupRemoteControls()
            startPlayback(song: song)
            togglePlayPause()
            isPlaying = false
            seek(to: snap.currentTime)
        }
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
        
        isStored = false
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
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = displayName.split(separator: " - ")[0]
        nowPlayingInfo[MPMediaItemPropertyArtist] = formatArtists(song.artists)
        Task { @MainActor [weak self] in
                guard let url = CoverFileManager.url(for: song),
                      FileManager.default.fileExists(atPath: url.path) else { return }

                if let image = UIImage.downsampledImage(at: url, to: 300, scale: UIScreen.main.scale),
                   let data = image.jpegData(compressionQuality: 0.8) {
                    let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in image }
                    self?.nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = self?.nowPlayingInfo
                }
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
    
    private func recordPlay(for song: Song) {
        guard let user = authManager?.currentUser else { return }
        let event = PlayHistory(completed: false, user: user, song: song)
        isStored = true
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
        playlistName: String,
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
            let genre_id = song.genre
            
            let currentID = song.id
            let fetch = FetchDescriptor<Song>(
                predicate: #Predicate<Song> { $0.id != currentID  }
            )
            
            if let allSongs = try? context.fetch(fetch) {
                let blockedSongIDs = Set(blockedSongs.map(\.id))
                let blockedArtistIDs = Set(blockedArtists.map(\.id))

                let filtered = allSongs.filter { song in
                    song.genre == genre_id &&
                    !blockedSongIDs.contains(song.id) &&
                    !song.artists.contains { blockedArtistIDs.contains($0.id)}
                }

                self.playlist += Array(filtered.shuffled().prefix(250))
                currentIndex = 0
            }
        }
        else if isOnlySong, let artist = artist {
            self.playlist = [song]
            let currentID = song.id
            
            let fetch = FetchDescriptor<Song>(
                predicate: #Predicate<Song> { $0.id != currentID }
            )

            if let allSongs = try? context.fetch(fetch) {
                let blockedSongIDs = Set(blockedSongs.map(\.id))
                let blockedArtistIDs = Set(blockedArtists.map(\.id))

                let filtered = allSongs.filter { s in
                    s.artists.contains(artist) &&
                    !blockedSongIDs.contains(s.id) &&
                    !s.artists.contains { blockedArtistIDs.contains($0.id) }
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
            currentIndex = shuffle ? 0 : songIndex
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
            self.markCurrentSongCompleted(secondPlayed: self.totalDuration)
            self.playNext()
        }
    }
    
    func stopQueue() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        removeTimeObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        
        nowPlayingInfo.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        currentSong = nil
        isPlaying = false
        currentTime = 0
        totalDuration = 0
        isShowingMiniPlayerBottom = false
        isShowingMiniPlayer = false
        playlist = []
        playlistTitle = ""
        currentIndex = 0
    }

    
    struct SongFileManager {
        static var documentsDirectory: URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        static func url(for song: Song) -> URL? {
            let dir = Self.documentsDirectory
            
            var filename = song.filepath
            let candidate = dir.appendingPathComponent(filename)
            return candidate
            
        }
    }
    private func updateNavigationButtons() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = currentIndex < playlist.count - 1
        commandCenter.previousTrackCommand.isEnabled = currentIndex > 0
    }

   
    func importSongs(from sourceURLs: [URL]) async {
        let documentsDir = Self.SongFileManager.documentsDirectory
        print("📁 Importing \(sourceURLs.count) files into:", documentsDir.path)
        Task{
            await Task.detached(priority: .userInitiated) {
                var count = 0
                for (i, sourceURL) in sourceURLs.enumerated() {
                    let filename = sourceURL.lastPathComponent
                    let destinationURL = documentsDir.appendingPathComponent(filename)
                    
                    do {
                        if !FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        }
                        count += 1
                    } catch {
                        print("❌ Error importing", filename, ":", error.localizedDescription)
                    }
                    
                    // Progress + give the runloop breathing room
                    if i % 100 == 0 {
                        print("Progress: \(i)/\(sourceURLs.count)")
                        
                        await Task.yield()
                        
                    }
                }
                print("✅ Done. \(count) files in Documents.")
            }
        }
    }
    struct CoverFileManager {
        static var documentsDirectory: URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        static func url(for song: Song) -> URL? {
            let dir = Self.documentsDirectory
            
            var filename = song.filepath.replacingOccurrences(of: ".mp3", with: ".jpg")
            let candidate = dir.appendingPathComponent(filename)
            return candidate
            
        }
    }
   
    func importCovers(from sourceURLs: [URL]) async {
        let documentsDir = Self.CoverFileManager.documentsDirectory
        print("📁 Importing \(sourceURLs.count) files into:", documentsDir.path)
        Task{
            await Task.detached(priority: .userInitiated) {
                var count = 0
                for (i, sourceURL) in sourceURLs.enumerated() {
                    let filename = sourceURL.lastPathComponent
                    let destinationURL = documentsDir.appendingPathComponent(filename)
                    
                    do {
                        if !FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        }
                        count += 1
                    } catch {
                        print("❌ Error importing", filename, ":", error.localizedDescription)
                    }
                    
                    // Progress + give the runloop breathing room
                    if i % 100 == 0 {
                        print("Progress: \(i)/\(sourceURLs.count)")
                        
                        await Task.yield()
                        
                    }
                }
                print("✅ Done. \(count) files in Documents.")
            }
        }
    }
    




    
    private func startPlayback(song: Song) {
       
        guard let url = SongFileManager.url(for: song) else {
            print("Could not find mp3 file for: \(song.title)")
            return
        }
        let item = AVPlayerItem(url: url)

        if let player = player {
            player.replaceCurrentItem(with: item)
        } else {
            player = AVPlayer(playerItem: item)
        }

        removeTimeObserver()
        setupTimeObserver()
        setupEndObserver()
        updateNavigationButtons()
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
        updateNavigationButtons()
        if currentIndex == playlist.count{
            stopQueue()
        }
        
        else{

            playSong(
                playlist[currentIndex],
                from: playlist,
                playlistName: playlistTitle,
                isOnlySong: false,
                preserveIndex: true
            )
        }
    }
    
    func playPrevious() {
        guard currentIndex > 0 else { return }
        updateNavigationButtons()
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
                if time.seconds >= 30 && !isStored{
                    recordPlay(for: currentSong!)
                }
                if time.seconds >= duration - 0.5 {
                    self.markCurrentSongCompleted(secondPlayed: duration)
                }
            }
            
            self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time.seconds
            self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? 1 : 0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
        }
    }
    
    private func markCurrentSongCompleted(secondPlayed: Double) {
        guard let user = authManager?.currentUser, let currentSong = currentSong else { return }
        
        let fetch = FetchDescriptor<PlayHistory>()
        if let histories = try? context.fetch(fetch),
           let latest = histories.last(where: {
               $0.user?.id == user.id && $0.song?.id == currentSong.id
           }) {
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
        if artists.count > 1 {
            let joined = artists.map { $0.name }.joined(separator: ", ")
            return joined
        } else {
            return artists.first?.name ?? "Anonymous"
        }
    }
}
