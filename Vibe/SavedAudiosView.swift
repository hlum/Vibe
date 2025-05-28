//
//  SavedAudiosView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData
import AVFoundation

final class SavedAudiosViewModel: ObservableObject {
    @Published var currentPlayer: AVPlayer?
    @Published var currentlyPlayingAudio: DownloadedAudio?
    @Published var currentPlaybackTime: Double = 0
    
    
    func playAudio(_ audio: DownloadedAudio) {
        print("Playing \(audio.title)")
        
        currentPlayer?.pause()
        
        // Get the Documents directory URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(audio.title).m4a")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: \(fileURL.path)")
            return
        }
        
        currentPlayer = AVPlayer(url: fileURL)
        currentlyPlayingAudio = audio
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session.")
        }
        
        currentPlayer?.play()
        currentPlaybackTime = currentPlayer?.currentTime().seconds ?? 0
        
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: currentPlayer?.currentItem,
            queue: .main) { [weak self] _ in
                self?.currentlyPlayingAudio = nil
                self?.currentPlaybackTime = 0
            }
        
    }
}

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
                        } else {
                            vm.playAudio(audio)
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
    var isPlaying: Bool
    @Binding var currentTime: TimeInterval
    var onPlayPause: () -> Void
    
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
