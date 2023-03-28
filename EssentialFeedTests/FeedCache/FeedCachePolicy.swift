//
//  FeedCachePolicy.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-03-28.
//

import Foundation

internal final class FeedCachePolicy {
    private init() {}
    
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxCache = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCache
    }
}
