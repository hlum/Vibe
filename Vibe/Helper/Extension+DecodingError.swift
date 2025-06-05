//
//  Extension+DecodingError.swift
//  Vibe
//
//  Created by cmStudent on 2025/06/04.
//

import Foundation

extension DecodingError {
    var detailedDescription: String {
        switch self {
        case .dataCorrupted(let context):
            return "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). \(context.debugDescription)"
            
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). \(context.debugDescription)"
            
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). \(context.debugDescription)"
            
        case .valueNotFound(let type, let context):
            return "Value not found for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). \(context.debugDescription)"
            
        @unknown default:
            return "Unknown decoding error: \(self.localizedDescription)"
        }
    }
}


