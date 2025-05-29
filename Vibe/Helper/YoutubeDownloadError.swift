//
//  YoutubeDownloadError.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation

enum YoutubeDownloaderError: LocalizedError {
    case invalidURL
    case invalidResponse
    case streamNotFound
    case downloadableURLNotFound
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Invalid URL", comment: "")
        case .downloadableURLNotFound:
            return NSLocalizedString("Downloadable URL not found.", comment: "")
        case .streamNotFound:
            return NSLocalizedString("Stream not found.", comment: "")
        case .invalidResponse:
            return NSLocalizedString("Invalid response from server", comment: "")
        case .decodingError(let error):
            return String(format: NSLocalizedString("Failed to decode response: %@", comment: ""), error.localizedDescription)
        case .networkError(let error):
            return String(format: NSLocalizedString("Network error: %@", comment: ""), error.localizedDescription)
        }
    }
}
