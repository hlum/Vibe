//
//  YoutubeDownloaderProtocol.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/29.
//
import Foundation

protocol DownloadableLinkConverter {
    func getDownloadableURL(from url: URL) async throws -> URL
}
