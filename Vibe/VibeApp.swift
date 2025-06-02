//
//  VibeApp.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import SwiftUI
import SwiftData

@main
struct VibeApp: App {
    
    private let container: ContainerProtocol
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        print(appSupport)
        let schema = Schema([
            DownloadedAudio.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.container = DepedencyContainer(modelContainer: container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }


    
    var body: some Scene {
        WindowGroup {
            
            MainTabView(
                savedAudioUseCase: container.savedAudioUseCase,
                audioPlayerUseCase: container.audioPlayerUseCase,
                youtubeDownloaderUseCase: container.youtubeDownloaderUseCase,
                youtubeVideoSearchUseCase: container.youtubeVideoSearchUseCase,
                playlistUseCase: container.playlistUseCase
            )
                .injectDependencies(container)
        }
        .modelContainer(container.modelContext.container)
    }
}


