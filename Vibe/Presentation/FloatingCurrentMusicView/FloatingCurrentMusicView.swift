//
//  FloatingCurrentMusicView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import SwiftUI
import Combine
import MusicSlider

enum IDForMatchedGeometry: Hashable {
    case image
    case title
}

@MainActor
final class FloatingCurrentMusicViewModel: ObservableObject {
    @Published var currentPlaybackTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentAudio: DownloadedAudio?
    @Published var loopOption: LoopOption = .loopPlaylist
    
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
        
        audioPlayerUseCase.loopOptionPublisher
            .assign(to: &$loopOption)
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
    
    func changeLoopOption(_ loopOption: LoopOption) async {
        await audioPlayerUseCase.changeLoopOption(loopOption)
    }
}

struct FloatingCurrentMusicView: View {
    @StateObject private var vm: FloatingCurrentMusicViewModel
    @State private var showCurrentPlayingDetail: Bool = false
    
    @State private var isSeeking: Bool = false
    @State private var sliderHeight: CGFloat = 10
    @State private var sliderValue: Double = 0
    
    
    @State private var dragStartTime: Date?
    @State private var dragTranslation: CGFloat = 0
    @Namespace private var animation
    
    init(audioPlayerUseCase: AudioPlayerUseCase) {
        _vm = .init(wrappedValue: .init(audioPlayerUseCase: audioPlayerUseCase))
    }
    var body: some View {
        if !showCurrentPlayingDetail {
            collapsedFloatingCurrentMusicView
                .transition(.scale(scale: 0.9, anchor: .topTrailing))
        } else {
            expandedFloatingCurrentMusicView
                .transition(.scale(scale: 0.1, anchor: .bottomLeading))
        }
    }
}


extension FloatingCurrentMusicView {
    private var expandedFloatingCurrentMusicView: some View {
        VStack(spacing: 16) {
            if let currentAudio = vm.currentAudio {
                
                CoverImageView(
                    imgURL: currentAudio.getImageURL() ?? "",
                    width: 200,
                    height: 200
                )
                .scaleEffect(CGFloat(1-(dragTranslation / 1000)))
                .offset(x: -dragTranslation / 4)


                
                // Song Title
                Text(currentAudio.title)
                    .matchedGeometryEffect(id: IDForMatchedGeometry.title, in: animation)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.dartkModeBlack)
                    .scaleEffect(CGFloat(1-(dragTranslation / 1000)))
                    .offset(x: -dragTranslation / 8)

                
                
                // Progress Bar
                VStack(spacing: 8) {
                    
                    MusicSlider(
                        value: $sliderValue,
                        totalValue: currentAudio.duration,
                        valueIndicatorColor: .dartkModeBlack.opacity(0.7),
                        heightOfSlider: $sliderHeight) {
                            Circle().opacity(0.00001)
                        } onChange: { value in
                            isSeeking = true
                            vm.currentPlaybackTime = value

                            withAnimation(.spring(response: 0.3)) {
                                sliderHeight = 20
                            }
                        } onEnded: { value in
                            sliderValue = value
                            vm.currentPlaybackTime = value
                            withAnimation(.spring(response: 0.3)) {
                                sliderHeight = 10
                            }
                            vm.seekToTime(vm.currentPlaybackTime)
                            // Delay setting isSeeking to false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSeeking = false
                            }
                        }
                        .scaleEffect(CGFloat(1-(dragTranslation / 1000)))
                        .onChange(of: vm.currentPlaybackTime) { _, newValue in
                            if !isSeeking {
                                self.sliderValue = newValue
                            }
                        }

                                        
                    HStack {
                        Text(formatDuration(self.sliderValue))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .scaleEffect(CGFloat(1-(dragTranslation / 1000)))

                        
                        Spacer()
                        
                        Text(formatDuration(currentAudio.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .scaleEffect(CGFloat(1-(dragTranslation / 1000)))

                    }
                }
                .padding(.horizontal)
                
                // Playback Controls
                HStack(spacing: 40) {
                    Button(action: vm.playPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.dartkModeBlack)
                            .scaleEffect(CGFloat(1-(dragTranslation / 1000)))

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
                            .foregroundColor(.dartkModeBlack)
                            .scaleEffect(CGFloat(1-(dragTranslation / 1000)))
                    }
                    
                    Button(action: vm.playNext) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.dartkModeBlack)
                            .scaleEffect(CGFloat(1-(dragTranslation / 1000)))
                    }
                }
                
                
                Button {
                    let allLoopOptions = LoopOption.allCases
                    if let currentIndex = allLoopOptions.firstIndex(of: vm.loopOption) {
                        withAnimation(.snappy) {
                            let nextLoopOption = allLoopOptions[(currentIndex + 1) % allLoopOptions.count]
                            Task {
                                await vm.changeLoopOption(nextLoopOption)
                            }
                        }
                    }
                } label: {
                    Image(systemName: vm.loopOption.imgName)
                        .font(.title2)
                        .foregroundColor(.green)
                        .scaleEffect(CGFloat(1-(dragTranslation / 1000)))
                }

            } else {
                Text("No audio playing")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.darkModeWhite)
        .shadow(color: .gray.opacity(0.4), radius: 10, x: 0, y: -4)
        .offset(y: dragTranslation)
        
        .gesture (
            DragGesture()
                .onChanged { value in
                    dragStartTime = dragStartTime ?? Date()
                    if value.translation.height > 0 { // only down drag
                        withAnimation(.smooth) {
                            dragTranslation = value.translation.height
                        }
                    }
                }
            
                .onEnded { value in
                    let dragEndTime = Date()
                    let dragDuration = dragEndTime.timeIntervalSince(dragStartTime ?? dragEndTime)
                    
                    let totalTranslation = value.translation.height
                    let velocity = dragDuration > 0 ? totalTranslation / CGFloat(dragDuration) : 0
                    
                    print("Velocity: \(velocity), Translation: \(totalTranslation)")
                    
                    let velocityThreshold: CGFloat = 1500
                    let distanceThreshold: CGFloat = 300
                    
                    if totalTranslation > distanceThreshold || velocity > velocityThreshold {
                        withAnimation(.smooth) {
                            showCurrentPlayingDetail.toggle()
                        }
                    }
                    
                    // Reset
                    dragStartTime = nil
                    withAnimation(.smooth) {
                        dragTranslation = 0
                    }
                }
        )
    }
    
    
    private var collapsedFloatingCurrentMusicView: some View {
        ZStack {
            Color.darkModeWhite
                .onTapGesture {
                    withAnimation(.smooth) {
                        showCurrentPlayingDetail.toggle()
                    }
                }
            HStack {
                
                CoverImageView(imgURL: vm.currentAudio?.getImageURL() ?? "")
                    .padding(.horizontal)
                    .matchedGeometryEffect(id: IDForMatchedGeometry.image, in: animation)
                
                
                Text(vm.currentAudio?.title ?? "No Music")
                    .foregroundStyle(.dartkModeBlack)
                    .matchedGeometryEffect(id: IDForMatchedGeometry.title, in: animation)
                    .font(.system(size: 14))
                    .lineLimit(1)
                
                
                Spacer()
                
                HStack(spacing: 0) {
                    Button {
                        print("Clicked")
                        if vm.isPlaying {
                            vm.pause()
                        } else {
                            vm.resume()
                        }
                    } label: {
                        Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundStyle(.dartkModeBlack)
                            .font(.system(size: 20))
                            .frame(width: 60)
                            .frame(maxHeight: .infinity)
                    }

                    
                    Button {
                        vm.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .foregroundStyle(.dartkModeBlack)
                            .font(.system(size: 20))
                            .frame(width: 60)
                            .frame(maxHeight: .infinity)
                    }
                }
                .padding(.trailing)


            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(.darkModeWhite)
        .cornerRadius(10)
        .padding(.horizontal, 10)
        .padding(.bottom, 70)
        .foregroundStyle(.dartkModeBlack)
        .shadow(color: .gray.opacity(0.4), radius:  10, x: 0, y: 0)

    }
    
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

}


#Preview {
    @Previewable
    @Environment(\.container) var container
    FloatingCurrentMusicView(audioPlayerUseCase: container.audioPlayerUseCase)
}
