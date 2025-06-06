//
//  LoopOption.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/06.
//


import Foundation

enum LoopOption: CaseIterable, Equatable {
    case loopPlaylist
    case loopOneSong
    case shuffle
    
    var imgName: String {
        switch self {
        case .loopPlaylist:
            "repeat"
        case .loopOneSong:
            "repeat.1"
        case .shuffle:
            "shuffle"
        }
    }
}
