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
        HStack(spacing: 20) {
            ZStack {
                
                if let imgURL = audio.imgURL {
                    
                    AsyncImage(url: URL(string: imgURL)) { image in
                        image
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                    } placeholder: {
                        placeHolderImageView
                    }
                    
                } else {
                    placeHolderImageView
                }
                
                if isPlaying {
                    Color.dartkModeBlack.opacity(0.6).frame(width: 50, height: 50).cornerRadius(10)
                    MusicVisualizerView(width: 20, height: 20)
                }
            }
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text(audio.title)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundStyle(.dartkModeBlack)
                
                Text("Downloaded: \(formatDate(audio.downloadDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        
    }
    
    private var placeHolderImageView: some View  {
        Image(systemName: "music.note")
            .foregroundStyle(.dartkModeBlack)
            .font(.system(size: 30))
            .foregroundColor(.black)
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
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
