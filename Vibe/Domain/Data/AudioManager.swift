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

class AudioManager: NSObject, AudioManagerRepository, AVAudioPlayerDelegate {
    
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
        setupInterruptionHandling()
    }
    
    deinit {
        stopCurrentPlayback()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Public Methods
extension AudioManager {
    
    
    func play(_ audio: DownloadedAudio) {
        stopCurrentPlayback()
        
        var fileURL: URL? = nil
        do {
            fileURL = try getLocalPath(for: audio)
        } catch {
            print("Error getting local file URL: \(error.localizedDescription)")
        }
        guard let fileURL else {
            print("FileURL not found.")
            return
        }
        
        
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
        
        // Update now playing info with new position
        if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func getAudioDuration(from url: URL) async throws -> Double {
        let player = try AVAudioPlayer(contentsOf: url)
        let duration = player.duration
        return duration
    }
}

// MARK: - Private Methods
private extension AudioManager {
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentPlaybackTime = time.seconds
        }
    }
    
    func setupPlaybackFinishedObserver() {
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
    
    func stopCurrentPlayback() {
        player?.pause()
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player = nil
        currentAudio = nil
        currentPlaybackTime = 0
        isPlaying = false
    }
}

// MARK: - Interruption Handling
private extension AudioManager {
    func setupInterruptionHandling() {
        // 他のアプリから音声を再生した
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // ヘッドポンかスピーカが変わった、外された
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began, pause playback
            print("Audio session interrupted")
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                // Interruption ended, resume playback
                print("Audio session interruption ended, resuming playback")
                resume()
            }
        @unknown default:
            break
        }
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged or bluetooth disconnected
            print("Audio route changed: old device unavailable")
            pause()
        default:
            break
        }
    }
}

// MARK: - KVO
extension AudioManager {
    override
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
    
    private func getLocalPath(for audio: DownloadedAudio) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let possibleFilenames = [
            "\(audio.title).m4a",  // Old format
            "\(audio.id).m4a"      // New, safer format
        ]
        
        for filename in possibleFilenames {
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("File found at path: \(fileURL.path)")
                return fileURL
            } else {
                print("File not found at path: \(fileURL.path)")
            }
        }

        throw URLError(.fileDoesNotExist)
    }
}

// MARK: - Now Playing Info
private extension AudioManager {
    func updateNowPlayingInfo(title: String, artist: String, duration: TimeInterval) {
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 // 1.0 = playing, 0.0 = paused

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
