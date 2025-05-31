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
                    currentPlaybackTime: $vm.currentPlaybackTime,
                    audio: audio,
                    isPlaying: vm.currentAudio?.id == audio.id && vm.isPlaying,
                    
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
                    }
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
                    }
                    .tint(.red)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Saved Audios")
    }
}

struct AudioItemRow: View {
    @Binding var currentPlaybackTime: Double
    
    let audio: DownloadedAudio
    var isPlaying: Bool
    var onPlayPause: () -> Void
    
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
                
                if isPlaying {
                    MusicVisualizerView(width: 20, height: 20)
                }
            }
            .padding(.horizontal)

        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onTapGesture {
            onPlayPause()
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


#Preview {
    @Previewable
    @Environment(\.container) var container
    SavedAudiosView(savedAudioUseCase: container.savedAudioUseCase, audioPlayerUseCase: container.audioPlayerUseCase)
}
