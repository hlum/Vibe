//
//  PlaylistRepository.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import Foundation
import SwiftData

@MainActor
protocol PlaylistRepository {
    func getAllPlaylists() async throws -> [Playlist]
    func getAllPlaylists(descriptor: FetchDescriptor<Playlist>) async throws -> [Playlist]
    
    func deletedPlaylist(_ playlist: Playlist) async throws
    func addPlaylist(_ playlist: Playlist) async throws
    func addSong(_ playlist: Playlist, song: DownloadedAudio) async throws
}
