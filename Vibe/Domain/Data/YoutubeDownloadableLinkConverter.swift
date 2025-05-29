//
//  YoutubeDownloadableLinkConverter.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import Foundation
import YouTubeKit

final class YoutubeDownloadableLinkConverter: DownloadableLinkConverter {
    
    func getDownloadableURL(from url: URL) async throws -> URL {
        
        let video = YouTube(url: url)
        let streams = try await video.streams
        let audioOnlyStreams = streams.filterAudioOnly()
        
        guard let stream = audioOnlyStreams.filter ({ $0.isNativelyPlayable }).highestAudioBitrateStream() else {
            throw YoutubeDownloaderError.streamNotFound
        }
        
        return stream.url
    }
    
}
