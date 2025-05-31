//
//  YoutubeSearchResponse.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import Foundation

struct YoutubeSearchResponse: Codable {
    let items: [YoutubeSearchItem]
}

struct YoutubeSearchItem: Codable {
    let snippet: Snippet
    let id: VideoID
}

struct VideoID: Codable {
    let videoId: String
}

struct Snippet: Codable {
    let title: String
    let thumbnail: Thumbnail
    
    enum CodingKeys: String, CodingKey {
        case title
        case thumbnail = "thumbnails"
    }
}

struct Thumbnail: Codable {
    let medium: ThumbnailInfo
}

struct ThumbnailInfo: Codable {
    let url: String
}
