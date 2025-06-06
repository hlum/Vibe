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
    
    init(id: String = UUID().uuidString, title: String, originalURL: String,imgURL: String? = nil, duration: TimeInterval = 0, playlist: [Playlist] = []) {
        self.id = id
        self.title = title
        self.originalURL = originalURL
        self.imgURL = imgURL
        self.downloadDate = Date()
        self.duration = duration
        self.playlist = playlist
    }
    
    
    func getImageURL() -> String? {
        guard let ImgURL = self.imgURL else {
            return nil
        }
        
        if ImgURL.starts(with: "http") {
            return ImgURL
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(ImgURL)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: \(fileURL.path)")
            return nil
        }
        
        return fileURL.path
    }
}
