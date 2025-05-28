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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DownloadedAudio.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
