//
//  MainTabViewModel.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//


import SwiftUI
import SwiftData

final class MainTabViewModel: ObservableObject {
    @Published var downloadingProcesses: [DownloadingProcess] = []
    @Published var youtubeURL: String = ""
    
    var youtubeDownloaderUseCase: YoutubeDownloaderUseCase
    var savedAudioUseCase: SavedAudioUseCase
    
    init(youtubeDownloaderUseCase: YoutubeDownloaderUseCase, savedAudioUseCase: SavedAudioUseCase) {
        self.youtubeDownloaderUseCase = youtubeDownloaderUseCase
        self.savedAudioUseCase = savedAudioUseCase
    }
    
    
    func downloadAndSave(fileName: String, youtubeURL: String) async {
        do {
            let localURL = await youtubeDownloaderUseCase.downloadAndGetLocalURL(fileName: fileName, youtubeLink: youtubeURL) { processes in
                DispatchQueue.main.async {
                    self.downloadingProcesses = processes
                }
            }
            
            guard let localURL else { return }
            
            let duration = try await AudioManager.shared.getAudioDuration(from: localURL)
            
            let downloadedAudio = DownloadedAudio(title: fileName, originalURL: youtubeURL, duration: duration)
                
            try await savedAudioUseCase.saveAudio(downloadedAudio)
            
            
        } catch {
            print("Error downloading: \(error.localizedDescription)")
        }
        
    }
}
