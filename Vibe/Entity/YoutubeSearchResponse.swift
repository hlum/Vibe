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
    
    static func getDummyItems() -> [YoutubeSearchItem] {
        let thumbnailInfo = ThumbnailInfo(url: "https://www.bigfootdigital.co.uk/wp-content/uploads/2020/07/image-optimisation-scaled.jpg")
        let thumbnail = Thumbnail(medium: thumbnailInfo)
        let snippet = Snippet(title: "Dummy Video Title", thumbnail: thumbnail)
        let videoID = VideoID(videoId: "dQw4w9WgXcQ")
        let item = YoutubeSearchItem(snippet: snippet, id: videoID)
        
        return [item,item,item,item,item,item,item,item,item]
    }

}

struct VideoID: Codable {
    let videoId: String
    
    func getYoutubeURL() -> String {
        "https://www.youtube.com/watch?v=\(videoId)"
    }
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
