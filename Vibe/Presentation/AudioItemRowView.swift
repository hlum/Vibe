//
//  AudioItemRowView.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import SwiftUI


class AudioItemRowViewModel: ObservableObject {
    @Published var showImagePicker: Bool = false
    @Published var selectedImage: UIImage?
    
    private var savedAudioUseCase: SavedAudioUseCase
    
    init(savedAudioUseCase: SavedAudioUseCase) {
        self.savedAudioUseCase = savedAudioUseCase
    }
    
    func changeCoverImage(audio: DownloadedAudio) async {
        guard let selectedImage = selectedImage else {
            print("No Image selected.")
            return
        }
        
        guard let localURL = saveImageToDisk(selectedImage, id: audio.id) else {
            print("Can't save image to the disk.")
            return
        }
        print("Saved to disk: \(localURL)")
        
        do {
            try await savedAudioUseCase.updateCoverImage(url: "\(audio.id).jpg", for: audio)
        } catch {
            print("Error updating cover image: \(error.localizedDescription)")
        }
    }
    
    
    private func saveImageToDisk(_ image: UIImage, id: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(id).jpg")
        
        do {
            try data.write(to: fileURL)
            return fileURL.path  // or fileURL.absoluteString
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

}

struct AudioItemRow: View {
    @StateObject var vm: AudioItemRowViewModel
    @Binding var currentPlaybackTime: Double
    
    
    init(savedAudioUseCase: SavedAudioUseCase, currentPlaybackTime: Binding<Double>, audio: DownloadedAudio, isPlaying: Bool) {
        _vm = .init(wrappedValue: .init(savedAudioUseCase: savedAudioUseCase))
        _currentPlaybackTime = currentPlaybackTime
        self.audio = audio
        self.isPlaying = isPlaying
    }
    
    let audio: DownloadedAudio
    var isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                let imgURL = audio.getImageURL()
                CoverImageView(imgURL: imgURL ?? "")
                
                
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
            
            Menu {
                Button("Change cover image", action: { vm.showImagePicker.toggle() })
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.dartkModeBlack)
                    .frame(width: 30, height: 30)
            }

        }
        .sheet(isPresented: $vm.showImagePicker, onDismiss: {
            Task {
                await vm.changeCoverImage(audio: audio)
            }
        }, content: {
            ImagePicker(selectedImage: $vm.selectedImage)
            
        })
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
