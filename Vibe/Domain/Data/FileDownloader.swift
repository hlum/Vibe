//
//  FileDownloaded.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation
import UIKit

class FileDownloader: NSObject, URLSessionDownloadDelegate, Downloader {
    
    func createNewInstance() -> Downloader {
        return FileDownloader()
    }
    
    private var progressHandler: ((Double, Int64, Int64) -> Void)?
    private var completionHandler: ((Result<URL, Error>) -> Void)?
    private var session: URLSession?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private static var sessionCounter = 0
    
    func download(
        from url: URL,
        progressHandler: @escaping (Double, Int64, Int64) -> Void,
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        print("FileDownloader: Starting download from URL: \(url)")
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Create unique identifier for this download session
        FileDownloader.sessionCounter += 1
        let sessionIdentifier = "com.vibe.backgroundDownload.\(FileDownloader.sessionCounter)"
        
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 3600
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        let task = session?.downloadTask(with: url)
        print("FileDownloader: Created download task with session identifier: \(sessionIdentifier)")
        task?.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else {
            print("FileDownloader: Invalid total bytes expected")
            return
        }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        self.progressHandler?(progress, totalBytesWritten, totalBytesExpectedToWrite)

    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("FileDownloader: Download completed successfully to: \(location)")
            self.completionHandler?(.success(location))
            self.cleanup()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("FileDownloader: Download failed with error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
                self.cleanup()
            }
        } else {
            print("FileDownloader: Download completed with no error")
                self.cleanup()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func cleanup() {
        print("FileDownloader: Cleaning up resources")
        endBackgroundTask()
        session?.invalidateAndCancel()
        session = nil
        progressHandler = nil
        completionHandler = nil
    }
    
    deinit {
        print("FileDownloader: Deinitializing")
        cleanup()
    }
}
