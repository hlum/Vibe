//
//  AudioManagerRepo.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import Combine

protocol AudioManagerRepository {
    var currentPlaybackTime: Double { get }
    var isPlaying: Bool { get }
    var currentAudio: DownloadedAudio? { get }
    
    var currentPlaybackTimePublisher: AnyPublisher<Double, Never> { get }
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentAudioPublisher: AnyPublisher<DownloadedAudio?, Never> { get }
    var playbackFinished: PassthroughSubject<Void, Never> { get }
    
    
    func play(_ audio: DownloadedAudio)
    func pause()
    func resume()
    func stop()
    func seek(to time: Double)
    func getAudioDuration(from url: URL) async throws -> Double
}
