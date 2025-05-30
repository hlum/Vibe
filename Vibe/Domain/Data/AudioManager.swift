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
        
        player = AVPlayer(url: fileURL)
     

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
        let player = AVAsset(url: url)
        return try await player.load(.duration).seconds
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
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
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
