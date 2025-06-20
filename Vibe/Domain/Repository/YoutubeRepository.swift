//
//  YoutubeRepository.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import Foundation

protocol YoutubeRepository {
    func fetchYoutubeVideos(searchWord: String, nextPageToken: String?) async throws -> ([YoutubeSearchItem], nextPageToken: String?)
}
