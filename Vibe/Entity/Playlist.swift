//
//  Playlist.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/02.
//

import Foundation
import SwiftData

@Model
class Playlist {
    var id: String
    var name: String
    var songs: [DownloadedAudio]
    
    
    init(id: String = UUID().uuidString, name: String, songs: [DownloadedAudio]) {
        self.id = id
        self.name = name
        self.songs = songs
    }
}


enum PlaylistType: Equatable {
    case all
    case playlist(Playlist)
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .playlist(let playlist):
            return playlist.name
        }
    }
}
