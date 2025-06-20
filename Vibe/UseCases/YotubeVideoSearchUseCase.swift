//
//  YotubeVideoSearchUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import Foundation

protocol YoutubeVideoSearchUseCase {
    func search(keyword: String, nextPageToken: String?) async throws -> ([YoutubeSearchItem], nextPageToken: String?)
}

final class YoutubeVideoSearchUseCaseImpl: YoutubeVideoSearchUseCase {
    private let youtubeRepo: YoutubeRepository
    
    init(youtubeRepo: YoutubeRepository) {
        self.youtubeRepo = youtubeRepo
    }
    
    func search(keyword: String, nextPageToken: String?) async throws -> ([YoutubeSearchItem], nextPageToken: String?) {
        return try await youtubeRepo.fetchYoutubeVideos(searchWord: keyword, nextPageToken: nextPageToken)
    }
}
