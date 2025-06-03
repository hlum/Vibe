//
//  AudioPlayerUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import Foundation
import Combine
import MediaPlayer

@MainActor
protocol AudioPlayerUseCase {
    var currentPlaybackTime: Double { get }
    var isPlaying: Bool { get }
    var currentAudio: DownloadedAudio? { get }
    var allSongs: [DownloadedAudio] { get }
    var currentPlaylistSongs: [DownloadedAudio] { get }
    var isLooping: Bool { get }
    
    var currentPlaybackTimePublisher: AnyPublisher<Double, Never> { get }
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentAudioPublisher: AnyPublisher<DownloadedAudio?, Never> { get }
    var isLoopingPublisher: AnyPublisher<Bool, Never> { get }
    
    func updateAllSongsList()
    func updateCurrentPlaylistSongs(playlistType: PlaylistType)
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
    
    @Published private(set) var allSongs: [DownloadedAudio] = []
    @Published private(set) var currentPlaylistSongs: [DownloadedAudio] = []
    
    @Published private(set) var isLooping: Bool = true
    private var currentIndex: Int = -1
    private var cancellables = Set<AnyCancellable>()
    private var playCommandHandler: Any?
    private var pauseCommandHandler: Any?
    private var nextTrackCommandHandler: Any?
    private var previousTrackCommandHandler: Any?
    
    deinit {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
    }
    
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
        fetchAllSongs()
        setupPlaybackFinishedHandler()
        setupRemoteCommandCenter()
    }
    
    
    private func fetchAllSongs() {
        Task {
            do {
                allSongs = try await savedAudioUseCase.getSavedAudios(playlistType: .all)
                currentPlaylistSongs = allSongs
            } catch {
                print("Error loading playlist: \(error.localizedDescription)")
            }
        }
    }
    
    // Update the local arrays of all songs after adding or deleting songs
    func updateAllSongsList() {
        Task {
            do {
                allSongs = try await savedAudioUseCase.getSavedAudios(playlistType: .all)
            } catch {
                print("Error loading playlist: \(error.localizedDescription)")
            }
        }
    }
    
    func updateCurrentPlaylistSongs(playlistType: PlaylistType) {
        Task {
            do {
                
                try await currentPlaylistSongs = savedAudioUseCase.getSavedAudios(playlistType: playlistType)
            } catch {
                print("Error updating currentPlaylist songs. \(error.localizedDescription)")
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
        if let index = allSongs.firstIndex(where: { $0.id == audio.id }) {
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
        guard !currentPlaylistSongs.isEmpty else { return }
        
        if currentIndex < currentPlaylistSongs.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
        
        audioManager.play(currentPlaylistSongs[currentIndex])
    }
    
    func playPrevious() {
        guard !currentPlaylistSongs.isEmpty else { return }
        
        if currentIndex > 0 {
            currentIndex -= 1
        } else {
            currentIndex = currentPlaylistSongs.count - 1
        }
        
        audioManager.play(currentPlaylistSongs[currentIndex])
    }
    
    func toggleLoop() {
        isLooping.toggle()
        print("Loop toggled: \(isLooping)")
    }
    
    
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Store handlers as properties to maintain strong references
        playCommandHandler = commandCenter.playCommand.addTarget { [self] event in
            Task { @MainActor in
                if self.isPlaying {
                    self.pause()
                } else {
                    if let currentAudio = self.currentAudio {
                        self.resume()
                    } else if let firstSong = self.currentPlaylistSongs.first {
                        self.play(firstSong)
                    }
                }
            }
            return .success
        }

        pauseCommandHandler = commandCenter.pauseCommand.addTarget { [weak self] event in
            
            if self?.isPlaying ?? false {
                    self?.pause()
                }
            
            return .success
        }

        nextTrackCommandHandler = commandCenter.nextTrackCommand.addTarget { [weak self] event in
            
                self?.playNext()
            
            return .success
        }
        
        previousTrackCommandHandler = commandCenter.previousTrackCommand.addTarget { [weak self] event in
            
                self?.playPrevious()
            
            return .success
        }
        
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                        let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                print("Failed to cast event to MPChangePlaybackPositionCommandEvent")
                      return .commandFailed
                  }
            
            let newPosition = positionEvent.positionTime
            guard newPosition >= 0 else {
                print("Failed newPosition < 0")
                       return .commandFailed
                   }
            
            self.seek(to: newPosition)
            return .success
        }
    }
    
}
