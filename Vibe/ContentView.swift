//
//  ContentView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI

final class MainTabViewModel: ObservableObject {
    @Published var downloadingProcesses: [DownloadingProcess] = []
    @Published var youtubeURL: String = ""
    
    let youtubeDownloader: YoutubeDownloader = YoutubeDownloader()
    
    
    init() {
        addListenerToDownloadProcesses()
    }
    
    func addListenerToDownloadProcesses() {
        youtubeDownloader.currentDownloadingProcesses = { [weak self] process in
            guard let self else { return }
            Task { @MainActor in
                self.downloadingProcesses = process
            }
        }
    }
    
    func downloadAndSave(fileName: String) {
        do {
            Task {
                let localURL = try await youtubeDownloader.downloadAudioAndSave(from: youtubeURL, fileName: fileName)
                print(localURL)
            }
        } catch {
            print("Error downloading file: \(error.localizedDescription)")
        }
    }
}

struct MainTabView: View {
    @StateObject private var vm: MainTabViewModel = .init()
    @State private var selectedTabIndex: Int = 0
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            SearchAndDownloadView(youtubeURL: $vm.youtubeURL, downloadingProcesses: $vm.downloadingProcesses, download: {fileName in
                vm.downloadAndSave(fileName: fileName)
            })
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(0)
            
            
            Text("Hello")
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Search")
                }
                .tag(1)
            //                DownloadedVideoListView(downloadedVideoURLs: [])
            //                    .tabItem {
            //                        Image(systemName: "folder")
            //                        Text("Downloaded")
            //                    }
        }
    }
}

#Preview {
    MainTabView()
}
