//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-03-01.
//

import XCTest
import EssentialFeed

class FeedStore {
    var deleteCacheStoreCount = 0
    
    func deleteCacheFeed() {
        deleteCacheStoreCount += 1
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ feedItems: [FeedItem]) {
        store.deleteCacheFeed()
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCacheStoreCount, 0)
        
    }
    
    func test_save_requestCacheDeletion() {
        
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems)
        
        XCTAssertEqual(store.deleteCacheStoreCount, 1)
    }
    
    //MARK: HELPER
    
    func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "www.yahho.com")!
    }

}
