//
//  MainTabViewModel.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//


import SwiftUI
import SwiftData

@MainActor
final class MainTabViewModel: ObservableObject {
    @Published var downloadingProcesses: [DownloadingProcess] = []
    @Published var keyword: String = ""
    @Published var currentAudio: DownloadedAudio?
    @Published var searchResults: [YoutubeSearchItem] = []
    
    private var youtubeDownloaderUseCase: YoutubeDownloaderUseCase
    private var savedAudioUseCase: SavedAudioUseCase
    private var audioPlayerUseCase: AudioPlayerUseCase
    private var youtubeVideoSearchUseCase: YoutubeVideoSearchUseCase
    
    init(
        youtubeDownloaderUseCase: YoutubeDownloaderUseCase,
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        youtubeVideoSearchUseCase: YoutubeVideoSearchUseCase
    ) {
        self.youtubeDownloaderUseCase = youtubeDownloaderUseCase
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.youtubeVideoSearchUseCase = youtubeVideoSearchUseCase
        setupBinding()
    }
    
    func setupBinding() {

        audioPlayerUseCase.currentAudioPublisher
            .assign(to: &$currentAudio)
        
    }
    
    
    func search() async {
        do {
            self.searchResults = try await youtubeVideoSearchUseCase.search(keyword: keyword)
        } catch {
            if let decodingError = error as? DecodingError {
                print("Decoding Error: \(decodingError.detailedDescription)")
            } else {
                print("Error searching youtube video: \(error.localizedDescription)")
            }
        }
    }

    
    
    func downloadAndSave(fileName: String, keyword: String, imgURL: String) async {
        do {
            let downloadedPath = await youtubeDownloaderUseCase.downloadAndGetLocalURL(fileName: fileName, youtubeLink: keyword) { processes in
                DispatchQueue.main.async {
                    self.downloadingProcesses = processes
                }
            }
            guard let downloadedPath else { return }
            
            let idForDownloadedAudio = UUID().uuidString
            let localURL = saveFile(from: downloadedPath, id: idForDownloadedAudio)
            
            guard let localURL else { return }
            
            let duration = try await audioPlayerUseCase.getDuration(for: localURL)
            let downloadedAudio = DownloadedAudio(id: idForDownloadedAudio, title: fileName, originalURL: keyword, imgURL: imgURL, duration: duration)
                
            try await savedAudioUseCase.saveAudio(downloadedAudio)
            audioPlayerUseCase.updateAllSongsList()
            
        } catch {
            print("Error downloading: \(error.localizedDescription)")
        }
        
    }
    
    
    private func saveFile(from url: URL, id: String) -> URL? {
        
        guard let data = try? Data(contentsOf: url) else {
            print("No data found at downloadedPath.")
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            try FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error.localizedDescription)")
            return nil
        }
        
        let localURL = documentsPath.appendingPathComponent("\(id).m4a")
        
        
        do {
            if FileManager.default.fileExists(atPath: localURL.path()) {
                try FileManager.default.removeItem(at: localURL)
            }
            try data.write(to: localURL)
            print("Successfully saved file to \(localURL.path)")
            return localURL
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            return nil
        }
    }

}
