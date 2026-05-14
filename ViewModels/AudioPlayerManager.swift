//
//  AudioPlayerManager.swift
//  music
//
//  Created by Anel Torić on 24. 2. 26.
//

import Foundation
import SwiftUI
import AVFoundation
internal import Combine

class AudioPlayerManager: ObservableObject{
    
    @Published var isPlaying = false
    @Published var currentTime :Double = 0
    @Published var duration : Double = 0
    @Published var volume : Float = 1.0
    
    var player: AVAudioPlayer?
    var timer : Timer?
    
    func load(song :String,type:String = "mp3"){
        guard let url = Bundle.main.url(forResource: song, withExtension: type) else{
            print("File not found")
            return
        }
        do{
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            player?.volume = volume
            
            startTimer()
            
            
        }
        catch{
            print(error.localizedDescription)
        }
    }
    func playPause(){
        guard let player else {return}
        
        if player.isPlaying{
            player.pause()
            isPlaying = false
        }else
        {
            player.play()
            isPlaying = true
        }
    }
    func stop()
    {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
    }
    func setVolume(_ value : Float){
        volume = value
        player?.volume = value
    }
    func seek(to time : Double){
        player?.currentTime = time
        currentTime = time
    }
    func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            
            guard let self = self,
                  let player = self.player else { return }
            
            DispatchQueue.main.async {
                self.currentTime = player.currentTime
                self.duration = player.duration
                self.isPlaying = player.isPlaying
            }
        }
    }
}

