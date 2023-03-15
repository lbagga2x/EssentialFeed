//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-03-15.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    public typealias SaveResult = Error?
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feedItems: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheError = error {
                completion(cacheError)
            } else {
                self.cache(feedItems, with: completion)
            }
         
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items, currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
}
