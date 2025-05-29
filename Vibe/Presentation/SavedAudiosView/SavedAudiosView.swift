//
//  SavedAudiosView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData
import AVFoundation

struct SavedAudiosView: View {
    @Query private var savedAudios: [DownloadedAudio]
    @StateObject private var vm: SavedAudiosViewModel
    @Environment(\.container) private var container
    
    init(savedAudioUseCase: SavedAudioUseCase, audioPlayerUseCase: AudioPlayerUseCase) {
        _vm = .init(wrappedValue: SavedAudiosViewModel(
            savedAudioUseCase: savedAudioUseCase,
            audioPlayerUseCase: audioPlayerUseCase
        ))
    }
    
    var body: some View {
        List {
            ForEach(savedAudios) { audio in
                AudioItemRow(
                    audio: audio,
                    isPlaying: vm.currentAudio?.id == audio.id && vm.isPlaying,
                    isLooping: $vm.isLooping,
                    currentTime: $vm.currentPlaybackTime,
                    onPlayPause: {
                        if vm.currentAudio?.id == audio.id {
                            if vm.isPlaying {
                                vm.pauseAudio()
                            } else {
                                vm.resumeAudio()
                            }
                        } else {
                            vm.playAudio(audio)
                        }
                    },
                    onSeek: { time in
                        vm.seekToTime(time)
                    },
                    onNext: vm.playNext,
                    onPrevious: vm.playPrevious,
                    onToggleLoop: vm.toggleLoop
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        Task {
                            await vm.delete(audio)
                        }
                    } label: {
                        Text("Delete")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Saved Audios")
    }
}

struct AudioItemRow: View {
    @State private var isEditing = false
    @State private var sliderValue: Double = 0
    
    let audio: DownloadedAudio
    var isPlaying: Bool
    @Binding var isLooping: Bool
    @Binding var currentTime: TimeInterval
    var onPlayPause: () -> Void
    var onSeek: (TimeInterval) -> Void
    var onNext: () -> Void
    var onPrevious: () -> Void
    var onToggleLoop: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audio.title)
                        .font(.headline)
                    
                    Text("Downloaded: \(formatDate(audio.downloadDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            if isPlaying {
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        Button(action: onPrevious) {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onToggleLoop) {
                            Image(systemName: isLooping ? "repeat.1" : "repeat")
                                .font(.title2)
                                .foregroundColor(isLooping ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onNext) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    
                    Slider(value: Binding(get: {
                        sliderValue
                    }, set: { newValue in
                        sliderValue = newValue
                        currentTime = newValue
                    }), in: 0...audio.duration) { editing in
                        isEditing = editing
                        if !editing {
                            onSeek(sliderValue)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text(formatDuration(currentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(audio.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onChange(of: currentTime) { _, newValue in
            if !isEditing {
                sliderValue = newValue
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


