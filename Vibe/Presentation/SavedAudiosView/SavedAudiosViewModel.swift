//
//  SavedAudiosViewModel.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//


import SwiftUI
import SwiftData
import AVFoundation
import Combine

@MainActor
final class SavedAudiosViewModel: ObservableObject {
    @Published var currentPlaybackTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentAudio: DownloadedAudio?
    @Published var isLooping: Bool = false
    
    private let savedAudioUseCase: SavedAudioUseCase
    private let audioPlayerUseCase: AudioPlayerUseCase
    private var cancellables = Set<AnyCancellable>()
    
    init(savedAudioUseCase: SavedAudioUseCase, audioPlayerUseCase: AudioPlayerUseCase) {
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to audio player use case publishers
        audioPlayerUseCase.currentPlaybackTimePublisher
            .assign(to: &$currentPlaybackTime)
        
        audioPlayerUseCase.isPlayingPublisher
            .assign(to: &$isPlaying)
        
        audioPlayerUseCase.currentAudioPublisher
            .assign(to: &$currentAudio)
            
        audioPlayerUseCase.isLoopingPublisher
            .assign(to: &$isLooping)
    }
    
    func seekToTime(_ seconds: Double) {
        audioPlayerUseCase.seek(to: seconds)
    }
    
    func playAudio(_ audio: DownloadedAudio) {
        if currentAudio?.id == audio.id {
            if isPlaying {
                pauseAudio()
            } else {
                resumeAudio()
            }
        } else {
            audioPlayerUseCase.play(audio)
        }
    }
    
    func pauseAudio() {
        print("ViewModel: Pausing audio")
        audioPlayerUseCase.pause()
    }
    
    func resumeAudio() {
        print("ViewModel: Resuming audio")
        audioPlayerUseCase.resume()
    }
    
    func playNext() {
        audioPlayerUseCase.playNext()
    }
    
    func playPrevious() {
        audioPlayerUseCase.playPrevious()
    }
    
    func toggleLoop() {
        audioPlayerUseCase.toggleLoop()
    }
    
    func delete(_ audio: DownloadedAudio) async {
        do {
            if currentAudio?.id == audio.id {
                audioPlayerUseCase.stop()
            }
            try await savedAudioUseCase.deleteAudio(audio)
            audioPlayerUseCase.updatePlaylist()
        } catch {
            print("Error deleting audio: \(error.localizedDescription)")
        }
    }
}
