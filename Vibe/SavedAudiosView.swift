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
    
    private var swiftDataManager: SwiftDataManager?
    private var timeObserver: Any?
    
    deinit {
        if let timeObserver = timeObserver {
            currentPlayer?.removeTimeObserver(timeObserver)
        }
    }
    
    func setSwiftDataManager(_ swiftDataManager: SwiftDataManager) {
        self.swiftDataManager = swiftDataManager
    }
    
    func playAudio(_ audio: DownloadedAudio) {
        print("Playing \(audio.title)")
        
        currentPlayer?.pause()
        if let timeObserver = timeObserver {
            currentPlayer?.removeTimeObserver(timeObserver)
        }
        
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
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = currentPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentPlaybackTime = time.seconds
        }
        
        currentPlayer?.play()
        
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: currentPlayer?.currentItem,
            queue: .main) { [weak self] _ in
                self?.currentlyPlayingAudio = nil
                self?.currentPlaybackTime = 0
                if let timeObserver = self?.timeObserver {
                    self?.currentPlayer?.removeTimeObserver(timeObserver)
                }
            }
    }
    
    
    func delete(_ audio: DownloadedAudio) async {
        do {
            if self.currentlyPlayingAudio?.id == audio.id {
                self.currentPlayer?.pause()
                self.currentPlayer = nil
                currentPlaybackTime = 0
                if let timeObserver = self.timeObserver {
                    self.currentPlayer?.removeTimeObserver(timeObserver)
                }

            }
            try await swiftDataManager?.deleteDownloadedAudio(audio)
        } catch {
            print("Error deleting audio: \(error.localizedDescription)")
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
