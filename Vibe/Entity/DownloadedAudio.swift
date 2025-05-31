//
//  DownloadedAudio.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import SwiftData

@Model
final class DownloadedAudio {
    var id: UUID
    var title: String
    var originalURL: String
    var downloadDate: Date
    var duration: TimeInterval
    
    init(title: String, originalURL: String, duration: TimeInterval = 0) {
        self.id = UUID()
        self.title = title
        self.originalURL = originalURL
        self.downloadDate = Date()
        self.duration = duration
    }
}
