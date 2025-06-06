//
//  SwiftDataManager.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import SwiftData

@MainActor
class SwiftDataAudioRepoImpl : AudioDataRepository {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(_ downloadedAudio: DownloadedAudio) throws {
        context.insert(downloadedAudio)
        try context.save()
    }
    
    
    func updateCoverImage(url: String, for audio: DownloadedAudio) throws {
        audio.imgURL = url
        try context.save()
    }

    
    func fetchAllDownloadedAudio() throws -> [DownloadedAudio] {
        try fetchSongs()
    }
    
    func fetchPlaylistSongs(playlist: Playlist) throws -> [DownloadedAudio] {
        try fetchSongs(playlist: playlist)
    }
    
    private func fetchSongs(playlist: Playlist? = nil) throws -> [DownloadedAudio] {
        guard let playlist = playlist else {
            let descriptor = FetchDescriptor<DownloadedAudio>()
            return try context.fetch(descriptor)
        }

        return playlist.songs
    }
    
    
    func deleteDownloadedAudio(_ downloadedAudio: DownloadedAudio) throws {
        context.delete(downloadedAudio)
        try context.save()
    }
    
    
    func addToPlaylist(_ audio: DownloadedAudio, to playlist: Playlist) throws {
        playlist.songs.append(audio)
        try context.save()
    }
}
