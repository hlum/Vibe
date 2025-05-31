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
    let repository: AudioDataRepository
    
    init(audioRepo: AudioDataRepository) {
        self.repository = audioRepo
    }
    
    
    func saveAudio(_ downloadedAudio: DownloadedAudio) async throws {
        try await repository.save(downloadedAudio)
    }
    
    func getSavedAudios() async throws -> [DownloadedAudio] {
        try await repository.fetchAllDownloadedAudio()
    }
    
    func deleteAudio(_ audio: DownloadedAudio) async throws {
        
        let localURL = try getLocalPath(for: audio)
        try FileManager.default.removeItem(at: localURL)
        try await repository.deleteDownloadedAudio(audio)
    }
    
    private func getLocalPath(for audio: DownloadedAudio) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(audio.title).m4a")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: \(fileURL.path)")
            throw URLError(.fileDoesNotExist)
        }
        
        return fileURL
    }
    
}
