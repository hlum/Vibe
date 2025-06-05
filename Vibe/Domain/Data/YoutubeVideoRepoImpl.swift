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
    

    
    func fetchYoutubeVideos(searchWord: String) async throws -> [YoutubeSearchItem] {
        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: searchWord),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "30"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        
        guard let url = components?.url else {
            print("Cannot create URL")
            return []
        }
        print(url)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        let rawString = String(data: data, encoding: .utf8) ?? ""
    

        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200 else {
            print("Status code is not 200")
            print(rawString)
            return []
        }
        print(rawString)

        
        let decoder = JSONDecoder()
        // Parse as generic JSON first to filter out non-video items
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = jsonObject["items"] as? [[String: Any]] else {
            print("Failed to parse JSON structure")
            return []
        }
        
        // Filter to only video items before decoding
        let videoItemsData = itemsArray.filter { item in
            if let id = item["id"] as? [String: Any],
               let kind = id["kind"] as? String {
                return kind == "youtube#video"
            }
            return false
        }
        
        print("Total items received: \(itemsArray.count)")
        print("Video items after filtering: \(videoItemsData.count)")
        
        // Create filtered response data
        let filteredResponse = ["items": videoItemsData]
        let filteredData = try JSONSerialization.data(withJSONObject: filteredResponse)
        
        // Now decode with your existing model
        let youtubeVideoSearchResponse = try decoder.decode(YoutubeSearchResponse.self, from: filteredData)
        
        return youtubeVideoSearchResponse.items
    }
}
