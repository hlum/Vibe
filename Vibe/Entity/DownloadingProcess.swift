//
//  DownloadingProcess.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation

struct DownloadingProcess: Identifiable {
    let id: String
    let fileName: String
    var progress: Double
    let expectedByte: Double
    let finishedByte: Double
    
    init(id: String = UUID().uuidString, fileName: String, progress: Double, expectedByte: Double, finishedByte: Double) {
        self.id = id
        self.fileName = fileName
        self.progress = progress
        self.expectedByte = expectedByte
        self.finishedByte = finishedByte
    }

    
    
    static func dummyData() -> [DownloadingProcess] {
        return [
            DownloadingProcess(fileName: "Lynn Lynn", progress: 0.1, expectedByte: 1000000, finishedByte: 10000),
            DownloadingProcess(fileName: "Song 2", progress:0.20, expectedByte: 1000000, finishedByte: 10000),
            DownloadingProcess(fileName: "fasdfa", progress: 0.8, expectedByte: 1000000, finishedByte: 10000)
        ]
    }
    
    mutating
    func updateProgress(_ progress: Double) {
        self.progress = progress
    }
}
