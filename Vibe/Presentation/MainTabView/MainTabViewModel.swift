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
    var audioPlayerUseCase: AudioPlayerUseCase
    
    init(youtubeDownloaderUseCase: YoutubeDownloaderUseCase, savedAudioUseCase: SavedAudioUseCase, audioPlayerUseCase: AudioPlayerUseCase) {
        self.youtubeDownloaderUseCase = youtubeDownloaderUseCase
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
    }
    
    
    func downloadAndSave(fileName: String, youtubeURL: String) async {
        do {
            let localURL = await youtubeDownloaderUseCase.downloadAndGetLocalURL(fileName: fileName, youtubeLink: youtubeURL) { processes in
                DispatchQueue.main.async {
                    self.downloadingProcesses = processes
                }
            }
            
            guard let localURL else { return }
            
            
            // TODO: get the real duration
            let duration = try await audioPlayerUseCase.getDuration(for: localURL)
            let downloadedAudio = DownloadedAudio(title: fileName, originalURL: youtubeURL, duration: duration)
                
            try await savedAudioUseCase.saveAudio(downloadedAudio)
            
            
        } catch {
            print("Error downloading: \(error.localizedDescription)")
        }
        
    }
}
