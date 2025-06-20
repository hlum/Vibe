//
//  YoutubeVideoRepoImpl.swift
//  Vibe
//
//  Created by cmStudent on 2025/05/31.
//

import Foundation

final class YoutubeVideoRepoImpl: YoutubeRepository {
    var apiKey: String = ""
    
    init() {
        self.apiKey = fetchAPIKey()
    }
    
    private func fetchAPIKey() -> String {
        guard let path = Bundle.main.path(forResource: "APIKEY", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let apiKey = dict["API_KEY"] as? String else {
            fatalError("API KEY not found in Info.plist")
        }
        return apiKey
    }
    

    
    func fetchYoutubeVideos(searchWord: String, nextPageToken: String?) async throws -> ([YoutubeSearchItem], nextPageToken: String?) {
        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: searchWord),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "10"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let nextPageToken {
            components?.queryItems?.append(
                URLQueryItem(name: "pageToken", value: nextPageToken)
            )
        }
        
        guard let url = components?.url else {
            print("Cannot create URL")
            return ([], nil)
        }
        print(url)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        let rawString = String(data: data, encoding: .utf8) ?? ""
    

        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200 else {
            print("Status code is not 200")
            print(rawString)
            return ([], nil)
        }
//        print(rawString)

        
        let decoder = JSONDecoder()
        let youtubeVideoSearchResponse = try decoder.decode(YoutubeSearchResponse.self, from: data)
        
        let filteredResponse = youtubeVideoSearchResponse.items.filter { $0.id.kind == "youtube#video" }
        
        
        return (filteredResponse, youtubeVideoSearchResponse.nextPageToken)
    }
}
