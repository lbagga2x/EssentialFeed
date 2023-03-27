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
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feedItems: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheError = error {
                completion(cacheError)
            } else {
                self.cache(feedItems, with: completion)
            }
            
        }
    }
    
    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .found(let feed, let timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
                
            case  .found:
                completion(.success([]))
                
            case .empty:
                completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
                
            case .failure(_):
                self.store.deleteCacheFeed { _ in }
                
            case .found(_, let timestamp) where !self.validate(timestamp):
                self.store.deleteCacheFeed { _ in }
                
            case .empty, .found: break
            }
        }
        
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxCache = calendar.date(byAdding: .day, value: 7, to: timestamp) else {
            return false
        }
        return currentDate() < maxCache
    }
    
    private func cache(_ items: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items.toLocal(), currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)
        }
    }
}

