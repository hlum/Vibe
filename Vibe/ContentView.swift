//
//  ContentView.swift
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
        // Set up the listener after youtubeDownloader is initialized
        addListenerToDownloadProcesses()
    }
    
    func addListenerToDownloadProcesses() {
        youtubeDownloader?.currentDownloadingProcesses = { [weak self] processes in
            print("Updated")
            guard let self else {
                print("No self")
                return
            }
            DispatchQueue.main.async {
                print("Downloading process updated with \(processes.count) processes")
                self.downloadingProcesses = processes
            }
        }
    }
    
    func downloadAndSave(fileName: String) {
        Task {
            try await youtubeDownloader?.downloadAudioAndSave(from: youtubeURL, fileName: fileName)
        }
    }
}

struct MainTabView: View {
    @StateObject private var vm: MainTabViewModel = .init()
    @Environment(\.modelContext) private var modelContext
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
        }
        .onAppear {
            vm.setModelContext(modelContext)
        }
    }
}

#Preview {
    MainTabView()
}
