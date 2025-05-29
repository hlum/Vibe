//
//  AudioPlayerUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import Foundation
import Combine

@MainActor
protocol AudioPlayerUseCase {
    var currentPlaybackTime: Double { get }
    var isPlaying: Bool { get }
    var currentAudio: DownloadedAudio? { get }
    var playlist: [DownloadedAudio] { get }
    
    func play(_ audio: DownloadedAudio)
    func pause()
    func resume()
    func stop()
    func seek(to time: Double)
    func playNext()
    func playPrevious()
    func toggleLoop()
}

@MainActor
final class AudioPlayerUseCaseImpl: AudioPlayerUseCase {
    private let audioManager: AudioManagerRepository
    private let savedAudioUseCase: SavedAudioUseCase
    
    @Published private(set) var playlist: [DownloadedAudio] = []
    private var currentIndex: Int = -1
    private var isLooping: Bool = false
    
    var currentPlaybackTime: Double {
        audioManager.currentPlaybackTime
    }
    
    var isPlaying: Bool {
        audioManager.isPlaying
    }
    
    var currentAudio: DownloadedAudio? {
        audioManager.currentAudio
    }
    
    init(audioManager: AudioManagerRepository, savedAudioUseCase: SavedAudioUseCase) {
        self.audioManager = audioManager
        self.savedAudioUseCase = savedAudioUseCase
        setupPlaylist()
    }
    
    private func setupPlaylist() {
        Task {
            do {
                playlist = try await savedAudioUseCase.getSavedAudios()
            } catch {
                print("Error loading playlist: \(error.localizedDescription)")
            }
        }
    }
    
    func play(_ audio: DownloadedAudio) {
        if let index = playlist.firstIndex(where: { $0.id == audio.id }) {
            currentIndex = index
        }
        audioManager.play(audio)
    }
    
    func pause() {
        audioManager.pause()
    }
    
    func resume() {
        audioManager.resume()
    }
    
    func stop() {
        audioManager.stop()
        currentIndex = -1
    }
    
    func seek(to time: Double) {
        audioManager.seek(to: time)
    }
    
    func playNext() {
        guard !playlist.isEmpty else { return }
        
        if currentIndex < playlist.count - 1 {
            currentIndex += 1
        } else if isLooping {
            currentIndex = 0
        } else {
            return
        }
        
        audioManager.play(playlist[currentIndex])
    }
    
    func playPrevious() {
        guard !playlist.isEmpty else { return }
        
        if currentIndex > 0 {
            currentIndex -= 1
        } else if isLooping {
            currentIndex = playlist.count - 1
        } else {
            return
        }
        
        audioManager.play(playlist[currentIndex])
    }
    
    func toggleLoop() {
        isLooping.toggle()
    }
}
