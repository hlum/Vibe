//
//  YoutubeDownloader.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import YouTubeKit

protocol YoutubeDownloaderProtocol {
    func downloadAudioAndSave(
        from urlString: String,
        fileName: String,
        currentDownloadingProcesses: @escaping ([DownloadingProcess]) -> Void
    ) async throws
}

final class YoutubeDownloader: YoutubeDownloaderProtocol {
    private let swiftDataManager: SwiftDataManager
    private var currentDownloadingProcesses: (([DownloadingProcess]) -> Void)?
    private var currentProcesses: [DownloadingProcess] = []
    private var activeDownloads: [String: FileDownloader] = [:]
    private let maxRetries = 3
    
    init(swiftDataManager: SwiftDataManager) {
        self.swiftDataManager = swiftDataManager
    }
    
    func downloadAudioAndSave(
        from urlString: String,
        fileName: String,
        currentDownloadingProcesses: @escaping ([DownloadingProcess]) -> Void
    ) async throws {
        self.currentDownloadingProcesses = currentDownloadingProcesses
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
            
            let downloadedURL = try await downloadFileWithRetry(fileName: fileName, from: downloadableURL)
            let data = try Data(contentsOf: downloadedURL)
            
            let localURL = try saveFile(with: data, fileName: fileName)
            let duration = try await AudioManager.shared.getAudioDuration(from: localURL)
            let downloadedAudio = DownloadedAudio(title: fileName, originalURL: urlString, duration: duration)
            try await swiftDataManager.save(downloadedAudio)
            
        } catch {
            print("Error downloading file: \(error.localizedDescription)")
            throw error
        }
    }
        
    private func getDownloadableURL(from url: URL) async throws -> URL? {
        do {
            let video = YouTube(url: url)
            let streams = try await video.streams
            let audioOnlyStreams = streams.filterAudioOnly()
            
            guard let stream = audioOnlyStreams.filter ({ $0.isNativelyPlayable }).highestAudioBitrateStream() else {
                throw YoutubeDownloaderError.streamNotFound
            }
            
            return stream.url
        } catch {
            throw YoutubeDownloaderError.decodingError(error)
        }
    }
    
    
    private func downloadFileWithRetry(fileName: String, from url: URL) async throws -> URL {
        var retryCount = 0
        var lastError: Error?
        
        while retryCount < maxRetries {
            do {
                return try await downloadFile(fileName: fileName, from: url)
            } catch {
                lastError = error
                retryCount += 1
                
                if retryCount < maxRetries {
                    // Wait before retrying (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw YoutubeDownloaderError.networkError(lastError ?? NSError(domain: "YoutubeDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed after \(maxRetries) retries"]))
    }
    
    private func downloadFile(fileName: String, from url: URL) async throws -> URL {
        var currentProcess = DownloadingProcess(fileName: fileName, progress: 0, expectedByte: 0, finishedByte: 0)
        var hasResumed = false
        
        // Create a new downloader and store it
        let fileDownloader = FileDownloader()
        activeDownloads[currentProcess.id] = fileDownloader
        
        return try await withCheckedThrowingContinuation { continuation in
            fileDownloader
                .download(from: url) { progress,finishedByte,totalByte in
                    currentProcess = DownloadingProcess(id: currentProcess.id, fileName: fileName, progress: progress, expectedByte: Double(totalByte), finishedByte: Double(finishedByte))
                    self.updateDownloadingProcess(currentProcess)
                } completionHandler: { [weak self] result in
                    guard let self = self else { return }
                    guard !hasResumed else { return }
                    hasResumed = true
                    
                    // Clean up the downloader
                    self.activeDownloads.removeValue(forKey: currentProcess.id)
                    
                    switch result {
                    case .success(let fileURL):
                        do {
                            // Read the file data immediately after download
                            let data = try Data(contentsOf: fileURL)
                            // Save the data to a permanent location
                            let savedURL = try self.saveFile(with: data, fileName: fileName)
                            self.removeDownloadingProcess(currentProcess)
                            continuation.resume(returning: savedURL)
                        } catch {
                            self.removeDownloadingProcess(currentProcess)
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        self.removeDownloadingProcess(currentProcess)
                        if let urlError = error as? URLError {
                            switch urlError.code {
                            case .networkConnectionLost, .notConnectedToInternet, .timedOut:
                                continuation.resume(throwing: YoutubeDownloaderError.networkError(error))
                            default:
                                continuation.resume(throwing: error)
                            }
                        } else {
                            continuation.resume(throwing: error)
                        }
                    }
                }
        }
    }
    
    private func saveFile(with data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error.localizedDescription)")
            throw YoutubeDownloaderError.networkError(error)
        }
        
        let localURL = documentsPath.appendingPathComponent("\(fileName).m4a")
        
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: localURL.path) {
                try FileManager.default.removeItem(at: localURL)
            }
            
            try data.write(to: localURL)
            print("Successfully saved file to: \(localURL.path)")
            return localURL
        } catch {
            print("Error saving file: \(error.localizedDescription)")
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
    
    deinit {
        // Clean up any remaining downloads
        activeDownloads.removeAll()
    }
}
