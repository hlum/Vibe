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
    func getAllPlaylists(descriptor: FetchDescriptor<Playlist>) async throws -> [Playlist]
}
