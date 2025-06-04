//
//  SwiftDataPlaylistRepository.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import Foundation
import SwiftData

@MainActor
class SwiftDataPlaylistRepository: PlaylistRepository {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    
    func getAllPlaylists() async throws -> [Playlist] {
        try await getAllPlaylists(descriptor: .init())
    }

    
    func getAllPlaylists(descriptor: FetchDescriptor<Playlist>) async throws -> [Playlist] {
        try context.fetch(descriptor)
    }
        
    
    func deletedPlaylist(_ playlist: Playlist) async throws {
        context.delete(playlist)
        try context.save()
    }
    
    
    func addPlaylist(_ playlist: Playlist) async throws {
        context.insert(playlist)
        try context.save()
    }
    
}
