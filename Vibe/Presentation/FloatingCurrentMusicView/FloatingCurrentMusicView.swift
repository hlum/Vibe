//
//  FloatingCurrentMusicView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import SwiftUI
import Combine

@MainActor
final class FloatingCurrentMusicViewModel: ObservableObject {
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

struct FloatingCurrentMusicView: View {
    @StateObject private var vm: FloatingCurrentMusicViewModel
    
    init(audioPlayerUseCase: AudioPlayerUseCase) {
        _vm = .init(wrappedValue: .init(audioPlayerUseCase: audioPlayerUseCase))
    }
    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .font(.system(size: 30))
                .foregroundColor(.black)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
            
            
            Text(vm.currentAudio?.title ?? "No Music")
                .font(.system(size: 14))
                .lineLimit(1)
            
            
            Spacer()
            
            HStack(spacing: 0) {
                Button {
                    if vm.isPlaying {
                        vm.pause()
                    } else {
                        vm.resume()
                    }
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)

                
                Button {
                    vm.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
            }
            .padding(.trailing)


        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(.thinMaterial)
        .cornerRadius(10)
        .padding(.horizontal, 10)
        .padding(.bottom, 70)
        .foregroundStyle(.black)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 2, y: 10)

    }
}


#Preview {
    @Previewable
    @Environment(\.container) var container
    FloatingCurrentMusicView(audioPlayerUseCase: container.audioPlayerUseCase)
}
