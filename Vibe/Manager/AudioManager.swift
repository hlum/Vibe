//
//  AudioManager.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import AVFoundation

final class AudioManager {
    
    func getAudioDuration(from url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }
}
