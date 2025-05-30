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
    var isLooping: Bool { get }
    
    var currentPlaybackTimePublisher: AnyPublisher<Double, Never> { get }
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentAudioPublisher: AnyPublisher<DownloadedAudio?, Never> { get }
    var isLoopingPublisher: AnyPublisher<Bool, Never> { get }
    
    func getDuration(for url: URL) async throws -> Double
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
    @Published private(set) var isLooping: Bool = false
    private var currentIndex: Int = -1
    private var cancellables = Set<AnyCancellable>()
    
    var currentPlaybackTime: Double {
        audioManager.currentPlaybackTime
    }
    
    var isPlaying: Bool {
        audioManager.isPlaying
    }
    
    var currentAudio: DownloadedAudio? {
        audioManager.currentAudio
    }
    
    var currentPlaybackTimePublisher: AnyPublisher<Double, Never> {
        audioManager.currentPlaybackTimePublisher
    }
    
    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        audioManager.isPlayingPublisher
    }
    
    var currentAudioPublisher: AnyPublisher<DownloadedAudio?, Never> {
        audioManager.currentAudioPublisher
    }
    
    var isLoopingPublisher: AnyPublisher<Bool, Never> {
        $isLooping.eraseToAnyPublisher()
    }
    
    init(audioManager: AudioManagerRepository, savedAudioUseCase: SavedAudioUseCase) {
        self.audioManager = audioManager
        self.savedAudioUseCase = savedAudioUseCase
        setupPlaylist()
        setupPlaybackFinishedHandler()
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
    
    private func setupPlaybackFinishedHandler() {
        audioManager.playbackFinished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("Playback finished, isLooping: \(self.isLooping)")
                if self.isLooping {
                    self.playNext()
                }
            }
            .store(in: &cancellables)
    }
    
    func getDuration(for url: URL) async throws -> Double {
        try await audioManager.getAudioDuration(from: url)
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
        } else {
            currentIndex = 0
        }
        
        audioManager.play(playlist[currentIndex])
    }
    
    func playPrevious() {
        guard !playlist.isEmpty else { return }
        
        if currentIndex > 0 {
            currentIndex -= 1
        } else {
            currentIndex = playlist.count - 1
        }
        
        audioManager.play(playlist[currentIndex])
    }
    
    func toggleLoop() {
        isLooping.toggle()
        print("Loop toggled: \(isLooping)")
    }
}
