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
    
    var youtubeDownloader: YoutubeDownloader?
    

    
    @MainActor
    func setModelContext(_ model: ModelContext) {
        youtubeDownloader = YoutubeDownloader(swiftDataManager: SwiftDataManager(context: model))
    }
    
    
    func downloadAndSave(fileName: String) async {
        do {
            try await youtubeDownloader?.downloadAudioAndSave(from: youtubeURL, fileName: fileName, currentDownloadingProcesses: { processes in
                DispatchQueue.main.async {
                    self.downloadingProcesses = processes
                }
            })
        } catch {
            print("Error downloading: \(error.localizedDescription)")
        }
        
    }
}