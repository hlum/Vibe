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
    var id: String
    var title: String
    @Relationship(inverse: \Playlist.songs) var playlist: [Playlist] = []
    var originalURL: String
    var imgURL: String?
    var downloadDate: Date
    var duration: TimeInterval
    
    init(title: String, originalURL: String,imgURL: String? = nil, duration: TimeInterval = 0, playlist: [Playlist] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.originalURL = originalURL
        self.imgURL = imgURL
        self.downloadDate = Date()
        self.duration = duration
        self.playlist = playlist
    }
}
