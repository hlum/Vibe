//
//  DepedencyContainer.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import SwiftUI
import SwiftData

@MainActor
protocol ContainerProtocol {
    var modelContext: ModelContext { get }
    var audioManagerRepo: AudioManagerRepository { get }
    var downloader: Downloader { get }
    var audioRepo: AudioRepository { get }
    var downloadableLinkConverter: DownloadableLinkConverter { get }
    
    var savedAudioUseCase: SavedAudioUseCase { get }
    var youtubeDownloaderUseCase: YoutubeDownloaderUseCase { get }
}

@MainActor
final class DepedencyContainer: ContainerProtocol {
    
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    var audioManagerRepo: AudioManagerRepository {
        AudioManager()
    }
    
    var downloader: Downloader {
        FileDownloader()
    }
    
    var downloadableLinkConverter: DownloadableLinkConverter {
        YoutubeDownloadableLinkConverter()
    }
    
    var audioRepo: AudioRepository {
        SwiftDataAudioRepoImpl(context: modelContext)
    }
    
    var savedAudioUseCase: SavedAudioUseCase {
        SwiftDataSavedAudioUseCaseImpl(audioRepo: audioRepo)
    }
    
    var youtubeDownloaderUseCase: YoutubeDownloaderUseCase {
        YoutubeDownloaderUseCaseImpl(downloadableLinkConverter: downloadableLinkConverter, downloader: downloader)
    }
    
}


private struct ContainerKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: ContainerProtocol = DepedencyContainer(
        modelContainer: try! ModelContainer(for: Schema([DownloadedAudio.self]))
    )
}

extension EnvironmentValues {
    var container: ContainerProtocol {
        get {
            self[ContainerKey.self]
        } set {
            self[ContainerKey.self] = newValue
        }
    }
}


extension View {
    func injectDependencies(_ container: ContainerProtocol) -> some View {
        environment(\.container, container)
    }
}



