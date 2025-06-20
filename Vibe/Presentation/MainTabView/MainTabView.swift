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
    private let playlistUseCase: PlaylistUseCase
    @State var floatingPlayerIsPresented: Bool = false
    @StateObject private var vm: MainTabViewModel
    
    init(
        savedAudioUseCase: SavedAudioUseCase,
        audioPlayerUseCase: AudioPlayerUseCase,
        youtubeDownloaderUseCase: YoutubeDownloaderUseCase,
        youtubeVideoSearchUseCase: YoutubeVideoSearchUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.savedAudioUseCase = savedAudioUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.playlistUseCase = playlistUseCase
        
        _vm = .init(wrappedValue: MainTabViewModel(youtubeDownloaderUseCase: youtubeDownloaderUseCase, savedAudioUseCase: savedAudioUseCase, audioPlayerUseCase: audioPlayerUseCase, youtubeVideoSearchUseCase: youtubeVideoSearchUseCase))
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    SavedAudiosView(
                        savedAudioUseCase: savedAudioUseCase,
                        audioPlayerUseCase: audioPlayerUseCase, playlistUseCase: playlistUseCase,
                        downloadingProcesses: $vm.downloadingProcesses,
                        floatingPlayerIsPresented: $floatingPlayerIsPresented
                    )
                }
                .tabItem {
                    Label("Saved", systemImage: "music.note.list")
                }
                .tag(0)
                NavigationStack {
                    SearchAndDownloadView(keyWord: $vm.keyword, searchResults: $vm.searchResults, download: { fileName, imgURL in
                        Task {
                            await vm.downloadAndSave(fileName: fileName, keyword: vm.keyword, imgURL: imgURL)
                        }
                    }, search: {
                        Task {
                            await vm.search()
                        }
                    },loadMore: {
                        Task {
                            await vm.loadMore()
                        }
                    }, showingFloatingPanel: vm.currentAudio != nil
                    )
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
               
                
            }
            
            FloatingCurrentMusicView(audioPlayerUseCase: audioPlayerUseCase)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .opacity(vm.currentAudio != nil ? 1 : 0)
                .onChange(of: vm.currentAudio) { _, newValue in
                    floatingPlayerIsPresented = newValue != nil
                }
            
        }
    }
}


#Preview {
    @Previewable
    @Environment(\.container) var container
    MainTabView(savedAudioUseCase: container.savedAudioUseCase, audioPlayerUseCase: container.audioPlayerUseCase, youtubeDownloaderUseCase: container.youtubeDownloaderUseCase, youtubeVideoSearchUseCase: container.youtubeVideoSearchUseCase, playlistUseCase: container.playlistUseCase)
}
