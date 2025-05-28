//
//  SwiftDataManager.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import SwiftData

@MainActor
class SwiftDataManager : SwiftDataAudioRepository {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(_ downloadedAudio: DownloadedAudio) throws {
        context.insert(downloadedAudio)
        try context.save()
    }
    
    func fetchAllDownloadedAudio() throws -> [DownloadedAudio] {
        let descriptor = FetchDescriptor<DownloadedAudio>()
        return try context.fetch(descriptor)
    }
    
    
    func deleteDownloadedAudio(_ downloadedAudio: DownloadedAudio) throws {
        context.delete(downloadedAudio)
        try context.save()
    }
}
