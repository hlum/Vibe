//
//  YoutubeRepository.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import Foundation

protocol YoutubeRepository {
    func fetchYoutubeVideos(searchWord: String) async throws -> [YoutubeSearchItem]
}
