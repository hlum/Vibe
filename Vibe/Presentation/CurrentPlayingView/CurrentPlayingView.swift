//
//  CurrentPlayingView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import SwiftUI
import Combine

struct CurrentPlayingView: View {
    @StateObject private var vm: CurrentPlayingViewModel
    
    init(audioPlayerUseCase: AudioPlayerUseCase) {
        _vm = StateObject(wrappedValue: CurrentPlayingViewModel(audioPlayerUseCase: audioPlayerUseCase))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let currentAudio = vm.currentAudio {
                // Album Art or Placeholder
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                // Song Title
                Text(currentAudio.title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                
                // Progress Bar
                VStack(spacing: 8) {
                    Slider(value: $vm.currentPlaybackTime, in: 0...currentAudio.duration) { editing in
                        if !editing {
                            vm.seekToTime(vm.currentPlaybackTime)
                        }
                    }
                    
                    HStack {
                        Text(formatDuration(vm.currentPlaybackTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(currentAudio.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Playback Controls
                HStack(spacing: 40) {
                    Button(action: vm.playPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        if vm.isPlaying {
                            vm.pause()
                        } else {
                            vm.resume()
                        }
                    }) {
                        Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: vm.playNext) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                
                // Loop Button
                Button(action: vm.toggleLoop) {
                    Image(systemName: vm.isLooping ? "repeat.1" : "repeat")
                        .font(.title2)
                        .foregroundColor(vm.isLooping ? .blue : .gray)
                }
            } else {
                Text("No audio playing")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color.darkModeWhite)
        .foregroundStyle(Color.dartkModeBlack)
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@MainActor
final class CurrentPlayingViewModel: ObservableObject {
    @Published var currentPlaybackTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentAudio: DownloadedAudio?
    @Published var isLooping: Bool = false
    
    private let audioPlayerUseCase: AudioPlayerUseCase
    private var cancellables = Set<AnyCancellable>()
    
    init(audioPlayerUseCase: AudioPlayerUseCase) {
        self.audioPlayerUseCase = audioPlayerUseCase
        setupBindings()
    }
    
    private func setupBindings() {
        audioPlayerUseCase.currentPlaybackTimePublisher
            .assign(to: &$currentPlaybackTime)
        
        audioPlayerUseCase.isPlayingPublisher
            .assign(to: &$isPlaying)
        
        audioPlayerUseCase.currentAudioPublisher
            .assign(to: &$currentAudio)
        
        audioPlayerUseCase.isLoopingPublisher
            .assign(to: &$isLooping)
    }
    
    func seekToTime(_ time: Double) {
        audioPlayerUseCase.seek(to: time)
    }
    
    func pause() {
        audioPlayerUseCase.pause()
    }
    
    func resume() {
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
}


