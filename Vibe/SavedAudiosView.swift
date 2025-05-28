//
//  SavedAudiosView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData

struct SavedAudiosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedAudios: [DownloadedAudio]
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var currentlyPlayingId: UUID?
    
    var body: some View {
        List {
            Text("\(savedAudios.count)")
            ForEach(savedAudios) { audio in
                AudioItemRow(
                    audio: audio,
                    isPlaying: currentlyPlayingId == audio.id,
                    currentTime: audioPlayer.currentTime,
                    onPlayPause: {
                        if currentlyPlayingId == audio.id {
                            if audioPlayer.isPlaying {
                                audioPlayer.pause()
                            } else {
                                audioPlayer.play(url: URL(string: audio.localURL)!)
                            }
                        } else {
                            audioPlayer.stop()
                            currentlyPlayingId = audio.id
                            audioPlayer.play(url: URL(string: audio.localURL)!)
                        }
                    }
                )
            }
        }
        .navigationTitle("Saved Audios")
    }
}

struct AudioItemRow: View {
    let audio: DownloadedAudio
    let isPlaying: Bool
    let currentTime: TimeInterval
    let onPlayPause: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(audio.title)
                    .font(.headline)
                Text(formatDuration(currentTime))
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
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    SavedAudiosView()
}
