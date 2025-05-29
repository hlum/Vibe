//
//  SavedAudioUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import Foundation

protocol SavedAudioUseCase {
    func saveAudio(_ downloadedAudio: DownloadedAudio) async throws
    func getSavedAudios() async throws -> [DownloadedAudio]
    func deleteAudio(_ audio: DownloadedAudio) async throws
}


class SwiftDataSavedAudioUseCaseImpl: SavedAudioUseCase {
    let repository: AudioRepository
    
    init(audioRepo: AudioRepository) {
        self.repository = audioRepo
    }
    
    
    func saveAudio(_ downloadedAudio: DownloadedAudio) async throws {
        try await repository.save(downloadedAudio)
    }
    
    func getSavedAudios() async throws -> [DownloadedAudio] {
        try await repository.fetchAllDownloadedAudio()
    }
    
    func deleteAudio(_ audio: DownloadedAudio) async throws {
        try await repository.deleteDownloadedAudio(audio)
    }
    
}
