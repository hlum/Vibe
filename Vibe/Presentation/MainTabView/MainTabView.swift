//
//  ContentView.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @StateObject private var vm: MainTabViewModel = .init()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTabIndex: Int = 0
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            SearchAndDownloadView(youtubeURL: $vm.youtubeURL, downloadingProcesses: $vm.downloadingProcesses, download: {fileName in
                Task {
                    await vm.downloadAndSave(fileName: fileName)
                }
            })
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(0)
            
            SavedAudiosView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Saved")
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
