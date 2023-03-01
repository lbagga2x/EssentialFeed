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
    var insertCallCount = 0
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    typealias DeletioCompletion = (Error?)-> Void
    private var deletionCompletions = [DeletioCompletion]()
    
    func deleteCacheFeed(completion: @escaping (Error?)-> Void) {
        deleteCacheStoreCount += 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
       deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feedItems: [FeedItem], _ timestamp: Date) {
        insertCallCount += 1
        insertions.append((feedItems, timestamp))
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ feedItems: [FeedItem]) {
        store.deleteCacheFeed { [unowned self] error in
            if error == nil {
                self.store.insert(feedItems, self.currentDate())
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCacheStoreCount, 0)
        
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems)
        
        XCTAssertEqual(store.deleteCacheStoreCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems)
        let deletionError = anyNSError()
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_requestNewCacheInsertionOnDeletion() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems)
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems)
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items , feedItems)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }
    
    //MARK: Helper

    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "www.yahho.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

}
