//
//  AudioManagerRepo.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation

protocol AudioManagerRepository {
    func getAudioDuration(from url: URL) async throws -> Double
}
