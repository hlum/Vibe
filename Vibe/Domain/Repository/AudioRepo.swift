//
//  SwiftDataAudioRepo.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation

@MainActor
protocol AudioRepository {
    func save(_ downloadedAudio: DownloadedAudio) throws
    func fetchAllDownloadedAudio() throws -> [DownloadedAudio]
    func deleteDownloadedAudio(_ downloadedAudio: DownloadedAudio) throws
}
