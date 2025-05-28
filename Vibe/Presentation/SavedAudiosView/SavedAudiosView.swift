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
    @Environment(\.modelContext) private var modelContext
    @Query private var savedAudios: [DownloadedAudio]
    @StateObject private var vm = SavedAudiosViewModel()
    
    var body: some View {
        List {
            ForEach(savedAudios) { audio in
                AudioItemRow(
                    audio: audio,
                    isPlaying: vm.currentlyPlayingAudio?.id == audio.id,
                    currentTime: $vm.currentPlaybackTime,
                    onPlayPause: {
                        if vm.currentlyPlayingAudio?.id == audio.id {
                            vm.currentPlayer?.pause()
                            vm.currentPlayer = nil
                            vm.currentlyPlayingAudio = nil
                            vm.currentPlaybackTime = 0
                        } else {
                            vm.playAudio(audio)
                        }
                    }
                )
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
        .navigationTitle("Saved Audios")
        .onAppear {
            vm.setSwiftDataManager(SwiftDataManager(context: modelContext))
        }
    }
}

struct AudioItemRow: View {
    let audio: DownloadedAudio
    var isPlaying: Bool
    @Binding var currentTime: TimeInterval
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
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            if isPlaying {
                ProgressView(value: currentTime, total: audio.duration)
                    .tint(.blue)
                
                HStack {
                    Text(formatDuration(currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDuration(audio.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
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
    SavedAudiosView()
}
