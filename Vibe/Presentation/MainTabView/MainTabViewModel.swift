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
    @Published var nextPageToken: String?
    
    @Published var isLoading: Bool = false
    
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
    
    
    deinit {
        Task { @MainActor in
            self.resetNextPageToken()
        }
    }

    
    func setupBinding() {

        audioPlayerUseCase.currentAudioPublisher
            .assign(to: &$currentAudio)
        
    }
    
    
    
    
    
    func search() async {
        do {
            isLoading = true
            let (searchResults, nextPageToken) = try await youtubeVideoSearchUseCase.search(keyword: keyword, nextPageToken: nextPageToken)
            
            self.searchResults = searchResults
            self.nextPageToken = nextPageToken
            isLoading = false
        } catch {
            if let decodingError = error as? DecodingError {
                print("Decoding Error: \(decodingError.detailedDescription)")
            } else {
                print("Error searching youtube video: \(error.localizedDescription)")
            }
        }
    }

    
    func loadMore() async {
        guard !isLoading else {
            print("Still loading previous page.")
            return
        }

        guard let token = nextPageToken else {
            print("No more page to load.")
            return
        }
        
        do {
            let (moreResults, token) = try await youtubeVideoSearchUseCase.search(keyword: keyword, nextPageToken: token)
            self.searchResults.append(contentsOf: moreResults)
            self.nextPageToken = token
            searchResults.forEach({ print($0.id.videoId) })
            isLoading = false
        } catch {
            print("Load more failed: \(error.localizedDescription)")
        }
    }
    
    
    func downloadAndSave(fileName: String, keyword: String, imgURL: String) async {
        do {
            let idForDownloadedAudio = UUID().uuidString

            let localURL = await youtubeDownloaderUseCase.downloadAndGetLocalURL(id: idForDownloadedAudio, fileName: fileName, youtubeLink: keyword) { processes in
                DispatchQueue.main.async {
                    self.downloadingProcesses = processes
                }
            }
            guard let localURL else { return }
            
                        
            let duration = try await audioPlayerUseCase.getDuration(for: localURL)
            let downloadedAudio = DownloadedAudio(id: idForDownloadedAudio, title: fileName, originalURL: keyword, imgURL: imgURL, duration: duration)
                
            try await savedAudioUseCase.saveAudio(downloadedAudio)
            audioPlayerUseCase.updateAllSongsList()
            
        } catch {
            print("Error downloading: \(error.localizedDescription)")
        }
        
    }
    
    
    func resetNextPageToken() {
        self.nextPageToken = nil
    }
    
    

}
