//
//  AudioManager.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import AVFoundation

final class AudioManager: AudioManagerRepository {
    static let shared = AudioManager()
    func getAudioDuration(from url: URL) async throws -> Double {
        let player = try AVAudioPlayer(contentsOf: url)
        return player.duration
    }
}
