//
//  SavedAudioUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import Foundation

protocol SavedAudioUseCase {
    func saveAudio(_ downloadedAudio: DownloadedAudio) async throws
    func getSavedAudios(playlistType: PlaylistType) async throws -> [DownloadedAudio]
    func deleteAudio(_ audio: DownloadedAudio) async throws
    func addToPlaylist(_ audio: DownloadedAudio, to playlist: Playlist) async 
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
        try await self.getSavedAudios(playlistType: .all)
    }
    
    func getSavedAudios(playlistType: PlaylistType) async throws -> [DownloadedAudio] {
        switch playlistType {
        case .all:
            return try await repository.fetchAllDownloadedAudio()
        case .playlist(let playlist):
            let audios =  try await repository.fetchPlaylistSongs(playlist: playlist)
            print(audios.count)
            return audios
        }
    }
    
    
    func deleteAudio(_ audio: DownloadedAudio) async throws {
        
        let localURL = try getLocalPath(for: audio)
        try FileManager.default.removeItem(at: localURL)
        try await repository.deleteDownloadedAudio(audio)
    }
    
    
    func addToPlaylist(_ audio: DownloadedAudio, to playlist: Playlist) async {
        do {
            try await repository.addToPlaylist(audio, to: playlist)
        } catch {
            print("Error adding song to playlist: \(error.localizedDescription)")
        }
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
