//
//  YoutubeDownloader.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import YouTubeKit


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


final class YoutubeDownloader {
    var currentDownloadingProcesses: (([DownloadingProcess]) -> Void)? = nil
    private let fileDownloader: FileDownloader = FileDownloader()
    private var currentProcesses: [DownloadingProcess] = []
    
    
    func downloadAudioAndSave(from urlString: String, fileName: String) async throws -> URL {
        guard !urlString.isEmpty else {
            throw YoutubeDownloaderError.invalidURL
        }
        
        guard let url = URL(string: urlString),
              url.host?.contains("youtube.com") == true || url.host?.contains("youtu.be") == true else {
            throw YoutubeDownloaderError.invalidURL
        }
        
        do {
            guard let downloadableURL = try await getDownloadableURL(from: url) else {
                throw YoutubeDownloaderError.downloadableURLNotFound
            }
            
            let downloadedURL = try await downloadFile(fileName: fileName, from: downloadableURL)
            let data = try Data(contentsOf: downloadedURL)
            
            return try saveFile(with: data, fileName: fileName)
        } catch let error as YoutubeDownloaderError {
            throw error
        } catch {
            throw YoutubeDownloaderError.networkError(error)
        }
    }
        
    private func getDownloadableURL(from url: URL) async throws -> URL? {
        
      
        let video = YouTube(url: url)
        let streams = try await video.streams
        let audioOnlyStreams = streams.filterAudioOnly()
        
        guard let stream = audioOnlyStreams.filter ({ $0.isNativelyPlayable }).highestAudioBitrateStream() else {
            throw YoutubeDownloaderError.streamNotFound
        }
        
        return stream.url
    }
    
    
    private func downloadFile(fileName: String, from url: URL) async throws -> URL {
        var currentProcess = DownloadingProcess(fileName: fileName, progress: 0)
        var hasResumed = false

        return try await withCheckedThrowingContinuation { continuation in
            fileDownloader.download(
                from: url) { progress in
                    currentProcess = DownloadingProcess(id: currentProcess.id, fileName: fileName, progress: progress)
                    self.updateDownloadingProcess(currentProcess)
                } completionHandler: { result in
                    guard !hasResumed else { return }
                    hasResumed = true
                    
                    switch result {
                    case .success(let fileURL):
                        self.removeDownloadingProcess(currentProcess)
                        continuation.resume(returning: fileURL)
                    case .failure(let error):
                        self.removeDownloadingProcess(currentProcess)
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    private func saveFile(with data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent("\(fileName).m4a")
        
        do {
            try data.write(to: localURL)
            return localURL
        } catch {
            throw YoutubeDownloaderError.networkError(error)
        }
    }
    
    
    
    private func removeDownloadingProcess(_ process: DownloadingProcess) {
        currentProcesses.removeAll { $0.id == process.id }
        currentDownloadingProcesses?(currentProcesses)
    }
    
    private func updateDownloadingProcess(_ process: DownloadingProcess) {
        if let currentDownloadingProcessesIndex = currentProcesses.firstIndex(where: { $0.id == process.id }) {
            currentProcesses[currentDownloadingProcessesIndex] = process
        } else {
            currentProcesses.append(process)
        }
        currentDownloadingProcesses?(currentProcesses)
    }

    
}
