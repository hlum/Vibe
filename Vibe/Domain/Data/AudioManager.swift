//
//  AudioManager.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer



final class AudioManager: NSObject, AudioManagerRepository, AVAudioPlayerDelegate  {
    
    // MARK: - Published Properties
    @Published private(set) var currentPlaybackTime: Double = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentAudio: DownloadedAudio?
    @Published private(set) var playbackFinished = PassthroughSubject<Void, Never>()
    
    var currentPlaybackTimePublisher: AnyPublisher<Double, Never> {
        $currentPlaybackTime.eraseToAnyPublisher()
    }
    
    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        $isPlaying.eraseToAnyPublisher()
    }
    
    var currentAudioPublisher: AnyPublisher<DownloadedAudio?, Never> {
        $currentAudio.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    override
    init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    func play(_ audio: DownloadedAudio) {
        stopCurrentPlayback()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(audio.title).m4a")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: \(fileURL.path)")
            return
        }
        
        print(fileURL)
        
        let asset = AVAsset(url: fileURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        
        // Trim the void at the end
        playerItem.forwardPlaybackEndTime = CMTime(seconds: audio.duration, preferredTimescale: 600)
        
        
        // Wait for the player item to be ready to play
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        currentAudio = audio
        
        setupTimeObserver()
        setupPlaybackFinishedObserver()
        player?.play()
        isPlaying = true
        
        Task {
            do {
                let duration = try await getAudioDuration(from: fileURL)
                updateNowPlayingInfo(title: audio.title, artist: "Unknown", duration: duration)
            } catch {
                print("Error updating now playing info: \(error.localizedDescription)")
            }
        }
    }
    
    func pause() {
        print("Pausing audio")
        player?.pause()
        isPlaying = false
    }
    
    func resume() {
        print("Resuming audio")
        player?.play()
        isPlaying = true
    }
    
    func stop() {
        print("Stopping audio")
        stopCurrentPlayback()
    }
    
    func seek(to time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: targetTime)
        self.currentPlaybackTime = time
    }
    
    
    func getAudioDuration(from url: URL) async throws -> Double {
        let player = try AVAudioPlayer(contentsOf: url)
        let duration = player.duration
        return duration
    }
    
    
    func updateNowPlayingInfo(title: String, artist: String, duration: TimeInterval) {
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 // 1.0 = playing, 0.0 = paused


        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status",
           let playerItem = object as? AVPlayerItem {
            switch playerItem.status {
            case .readyToPlay:
                print("Player item is ready to play")
            case .failed:
                print("Player item failed to load: \(String(describing: playerItem.error))")
            case .unknown:
                print("Player item status unknown")
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentPlaybackTime = time.seconds
        }
    }
    
    private func setupPlaybackFinishedObserver() {
        guard let playerItem = player?.currentItem else { return }
                
                // Clear previous subscriptions
                cancellables.removeAll()
                
                // Subscribe to playback completion using Combine
                NotificationCenter.default
                    .publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
                    .sink { [weak self] _ in
                        self?.playbackFinished.send()
                        self?.stopCurrentPlayback()
                    }
                    .store(in: &cancellables)
    }
    
    private func stopCurrentPlayback() {
        player?.pause()
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player = nil
        currentAudio = nil
        currentPlaybackTime = 0
        isPlaying = false
    }
    
    
    private func removeTimeObserver() {
         if let timeObserver = timeObserver {
             player?.removeTimeObserver(timeObserver)
             self.timeObserver = nil
         }
     }
    
    
    deinit {
        stopCurrentPlayback()
    }
}
