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
            return audios
        }
    }
    
    
    func deleteAudio(_ audio: DownloadedAudio) async throws {
        try await repository.deleteDownloadedAudio(audio)

        let localURL = try getLocalPath(for: audio)
        try FileManager.default.removeItem(at: localURL)
        

    }
    
    
    func updateCoverImage(url: String, for audio: DownloadedAudio) async throws {
        try await repository.updateCoverImage(url: url, for: audio)
    }

    
    
    func addToPlaylist(_ audio: DownloadedAudio, to playlist: Playlist) async {
        do {
            try await repository.addToPlaylist(audio, to: playlist)
        } catch {
            print("Error adding song to playlist: \(error.localizedDescription)")
        }
    }
    
    private func getLocalPath(for audio: DownloadedAudio) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let possibleFilenames = [
            "\(audio.title).m4a",  // Old format
            "\(audio.id).m4a"      // New, safer format
        ]
        
        for filename in possibleFilenames {
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("File found at path: \(fileURL.path)")
                return fileURL
            } else {
                print("File not found at path: \(fileURL.path)")
            }
        }

        throw URLError(.fileDoesNotExist)
    }

    
}
