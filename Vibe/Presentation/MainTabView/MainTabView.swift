//
//  ContentView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    private let savedAudioUseCase: SavedAudioUseCase
    private let audioPlayerUseCase: AudioPlayerUseCase
    
    @StateObject private var vm: MainTabViewModel
    
    init(
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        youtubeDownloaderUseCase: YoutubeDownloaderUseCase
    ) {
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        
        _vm = .init(wrappedValue: MainTabViewModel(youtubeDownloaderUseCase: youtubeDownloaderUseCase, savedAudioUseCase: savedAudioUseCase, audioPlayerUseCase: audioPlayerUseCase))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchAndDownloadView(youtubeURL: $vm.youtubeURL, downloadingProcesses: $vm.downloadingProcesses) { fileName in
                Task {
                    await vm.downloadAndSave(fileName: fileName, youtubeURL: vm.youtubeURL)
                }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(0)
            NavigationStack {
                SavedAudiosView(
                    savedAudioUseCase: savedAudioUseCase,
                    audioPlayerUseCase: audioPlayerUseCase
                )
            }
            .tabItem {
                Label("Saved", systemImage: "music.note.list")
            }
            .tag(1)
            
            NavigationStack {
                CurrentPlayingView(audioPlayerUseCase: audioPlayerUseCase)
            }
            .tabItem {
                Label("Now Playing", systemImage: "play.circle.fill")
            }
            .tag(2)
        }
    }
}

