//
//  Downloader.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/28.
//

import Foundation

protocol Downloader {
    func createNewInstance() -> Downloader
    func download(
        from url: URL,
        progressHandler: @escaping (Double, Int64, Int64) -> Void,
        completionHandler: @escaping (Result<URL, Error>) -> Void
    )
}
