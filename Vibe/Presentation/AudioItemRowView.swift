//
//  AudioItemRowView.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import SwiftUI

struct AudioItemRow: View {
    @Binding var currentPlaybackTime: Double
    
    let audio: DownloadedAudio
    var isPlaying: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audio.title)
                        .font(.headline)
                        .foregroundStyle(.dartkModeBlack)
                    
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
