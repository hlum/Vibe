//
//  YoutubeDownloaderUseCase.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//

import Foundation

protocol YoutubeDownloaderUseCase {
    func downloadAndGetLocalURL(
        fileName: String,
        youtubeLink: String,
        currentDownloadingProcessesUpdated: @escaping ([DownloadingProcess]) -> Void
    ) async -> URL?
}

class YoutubeDownloaderUseCaseImpl: YoutubeDownloaderUseCase {
    private let maxRetryCount: Int = 3
    private var currentDownloadingProcessesUpdated: (([DownloadingProcess]) -> Void)?
    private var currentProcesses: [DownloadingProcess] = []
    
    private let downloadableLinkConverter: DownloadableLinkConverter
    private let downloader: Downloader
    private var activeDownloads: [String: Downloader] = [:]

    
    init(
        downloadableLinkConverter: DownloadableLinkConverter,
        downloader: Downloader
    ) {
        self.downloadableLinkConverter = downloadableLinkConverter
        self.downloader = downloader
    }
    
    
    func downloadAndGetLocalURL(
        fileName: String,
        youtubeLink: String,
        currentDownloadingProcessesUpdated: @escaping ([DownloadingProcess]) -> Void
    ) async -> URL? {
    
        self.currentDownloadingProcessesUpdated = currentDownloadingProcessesUpdated
        
        guard let downloadableLink = await convertToDownloadableLink(youtubeLink: youtubeLink) else {
            print("Can't get to Downloadable URL.")
            return nil
        }
        
        guard let downloadedPath = await downloadFileWithRetry(fileName: fileName, from: downloadableLink) else {
            return nil
        }
        
        
        return downloadedPath
       
    }
    
    
}


extension YoutubeDownloaderUseCaseImpl {
    
    private func downloadFileWithRetry(fileName: String, from url: URL) async -> URL? {
        var retryCount = 0
        var lastError: Error?
        
        while retryCount < maxRetryCount {
            do {
                print("Download succeeded. No need to retry.")
                return try await downloadFile(fileName: fileName, from: url)
            } catch {
                print("Download Failed. Error: \(error). Retrying for \(retryCount + 1) times...")
                lastError = error
                retryCount += 1
                
                if retryCount < maxRetryCount {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                    continue
                }
            }
        }
        
        print("Download failed. Giving up after \(maxRetryCount) retries.")
        return nil
    }
    
    private func downloadFile(fileName: String, from url: URL) async throws -> URL {
        var hasResumed = false

        var currentProcess = DownloadingProcess(fileName: fileName, progress: 0, expectedByte: 0, finishedByte: 0)
        
        // Create new Downloader and store it.
        let fileDownloader = downloader.createNewInstance()
        activeDownloads[currentProcess.id] = fileDownloader
        
        return try await withCheckedThrowingContinuation { continuation in

            fileDownloader
                .download(from: url) { progress, finishedByte, totalByte in
                    
                    // update the downloading progress
                    currentProcess = DownloadingProcess(id: currentProcess.id, fileName: fileName, progress: progress, expectedByte: Double(totalByte), finishedByte: Double(finishedByte))
                    
                    self.updateDownloadingProcess(currentProcess)
                    
                } completionHandler: { [weak self] result in
                    guard let self = self else {
                        print("Lose self reference")
                        return
                    }
                    
                    guard !hasResumed else { return }
                    hasResumed = true
                    
                    // Clean up the downloader
                    self.activeDownloads.removeValue(forKey: currentProcess.id)
                    
                    switch result {
                    case .success(let fileURL):
                        continuation.resume(returning: fileURL)
                        self.removeDownloadingProcess(currentProcess)
                    case .failure(let error):
                        self.removeDownloadingProcess(currentProcess)
                        continuation.resume(throwing: error)
                        
                    }
                }

        }
        
    }
    
    
    
    private func removeDownloadingProcess(_ process: DownloadingProcess) {
        currentProcesses.removeAll { $0.id == process.id }
        currentDownloadingProcessesUpdated?(currentProcesses)
    }
    
    private func updateDownloadingProcess(_ process: DownloadingProcess) {
        if let currentDownloadingProcessesIndex = currentProcesses.firstIndex(where: { $0.id == process.id }) {
            currentProcesses[currentDownloadingProcessesIndex] = process
        } else {
            currentProcesses.append(process)
        }
        currentDownloadingProcessesUpdated?(currentProcesses)
    }

    private func convertToDownloadableLink(youtubeLink: String) async -> URL? {
        guard let url = URL(string: youtubeLink) else {
            return nil
        }
        do {
            return try await downloadableLinkConverter.getDownloadableURL(from: url)
        } catch {
            print("Error converting to downloadable link. \(error.localizedDescription)")
            return nil
        }
    }
}
