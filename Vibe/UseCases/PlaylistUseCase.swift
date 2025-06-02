//
//  PlaylistUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import Foundation

protocol PlaylistUseCase {
    func addPlaylist(_ playlist: Playlist) async
    func getAllPlaylists() async -> [Playlist]
    func deletePlaylist(_ playlist: Playlist) async
    func addSong(_ song: DownloadedAudio, to playlist: Playlist) async
}

class PlaylistUseCaseImpl: PlaylistUseCase {
    private let playlistRepository: PlaylistRepository
    
    init(playlistRepository: PlaylistRepository) {
        self.playlistRepository = playlistRepository
    }
    
    
    func addPlaylist(_ playlist: Playlist) async {
        do {
            try await playlistRepository.addPlaylist(playlist)
        } catch {
            print("Error adding playlist: \(error.localizedDescription)")
        }
    }
    
    
    func getAllPlaylists() async -> [Playlist] {
        do {
            return try await playlistRepository.getAllPlaylists()
        } catch {
            print("Error getting playlists: \(error.localizedDescription)")
            return []
        }
    }
    
    
    func deletePlaylist(_ playlist: Playlist) async {
        do {
            try await playlistRepository.deletedPlaylist(playlist)
        } catch {
            print("Error deleting playlist: \(error.localizedDescription)")
        }
    }
    
    func addSong(_ song: DownloadedAudio, to playlist: Playlist) async {
        do {
            try await playlistRepository.addSong(playlist, song: song)
        } catch {
            print("Error adding song to playlist: \(error.localizedDescription)")
        }
    }
}
