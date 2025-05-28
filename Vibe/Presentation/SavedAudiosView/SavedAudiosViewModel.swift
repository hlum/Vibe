//
//  SavedAudiosViewModel.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//


import SwiftUI
import SwiftData
import AVFoundation

final class SavedAudiosViewModel: ObservableObject {
    @Published var currentPlayer: AVPlayer?
    @Published var currentlyPlayingAudio: DownloadedAudio?
    @Published var currentPlaybackTime: Double = 0
    
    private var swiftDataManager: SwiftDataManager?
    private var timeObserver: Any?
    
    deinit {
        if let timeObserver = timeObserver {
            currentPlayer?.removeTimeObserver(timeObserver)
        }
    }
    
    func setSwiftDataManager(_ swiftDataManager: SwiftDataManager) {
        self.swiftDataManager = swiftDataManager
    }
    
    func playAudio(_ audio: DownloadedAudio) {
        print("Playing \(audio.title)")
        
        currentPlayer?.pause()
        if let timeObserver = timeObserver {
            currentPlayer?.removeTimeObserver(timeObserver)
        }
        
        // Get the Documents directory URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(audio.title).m4a")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: \(fileURL.path)")
            return
        }
        
        currentPlayer = AVPlayer(url: fileURL)
        currentlyPlayingAudio = audio
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session.")
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = currentPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentPlaybackTime = time.seconds
        }
        
        currentPlayer?.play()
        
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: currentPlayer?.currentItem,
            queue: .main) { [weak self] _ in
                self?.currentlyPlayingAudio = nil
                self?.currentPlaybackTime = 0
                if let timeObserver = self?.timeObserver {
                    self?.currentPlayer?.removeTimeObserver(timeObserver)
                }
            }
    }
    
    
    func delete(_ audio: DownloadedAudio) async {
        do {
            if self.currentlyPlayingAudio?.id == audio.id {
                self.currentPlayer?.pause()
                self.currentPlayer = nil
                currentPlaybackTime = 0
                if let timeObserver = self.timeObserver {
                    self.currentPlayer?.removeTimeObserver(timeObserver)
                }

            }
            try await swiftDataManager?.deleteDownloadedAudio(audio)
        } catch {
            print("Error deleting audio: \(error.localizedDescription)")
        }
    }
}