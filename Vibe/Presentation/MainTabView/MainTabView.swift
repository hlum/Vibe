//
//  ContentView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @StateObject private var vm: MainTabViewModel
    @Environment(\.container) private var container
    @State private var selectedTabIndex: Int = 0
    
    init(vm: MainTabViewModel) {
        _vm = .init(wrappedValue: vm)
    }
    
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            SearchAndDownloadView(youtubeURL: $vm.youtubeURL, downloadingProcesses: $vm.downloadingProcesses, download: {fileName in
                Task {
                    await vm.downloadAndSave(fileName: fileName, youtubeURL: vm.youtubeURL)
                }
            })
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(0)
            
            SavedAudiosView(
                savedAudioUseCase: container.savedAudioUseCase,
                audioPlayerUseCase: container.audioPlayerUseCase
            )
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Saved")
                }
                .tag(1)
        }
    }
}

