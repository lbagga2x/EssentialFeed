//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-03-01.
//

import XCTest
import EssentialFeed

class FeedStore {
   
    typealias DeletioCompletion = (Error?)-> Void
    private var deletionCompletions = [DeletioCompletion]()
    
    typealias InsertionCompletion = (Error?)-> Void
    private var insertionCompletions = [InsertionCompletion]()
    
    enum ReceivedMessage: Equatable {
        case insert([FeedItem],Date)
        case deleteCacheFeed
    }
    var receivedMesseges = [ReceivedMessage]()
    
    func deleteCacheFeed(completion: @escaping (Error?)-> Void) {
        deletionCompletions.append(completion)
        receivedMesseges.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
       deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feedItems: [FeedItem], _ timestamp: Date, completion: @escaping (Error?)-> Void) {
        insertionCompletions.append(completion)
        receivedMesseges.append(.insert(feedItems, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ feedItems: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCacheFeed { [unowned self] error in
          
            if error == nil {
                self.store.insert(feedItems, self.currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMesseges, [])
        
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems, completion: { _ in })
        
        XCTAssertEqual(store.receivedMesseges, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems, completion: { _ in })
        let deletionError = anyNSError()
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMesseges, [.deleteCacheFeed])
    }
        
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let feedItems = [uniqueItem(), uniqueItem()]
        sut.save(feedItems, completion: { _ in })
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMesseges, [.deleteCacheFeed, .insert(feedItems, timestamp)])
        
    }
    
    func test_save_onDeleteionError() {
        let (sut, store) = makeSUT()
 
        let deletionError = anyNSError()
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failOnInsertionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        let deletionError = anyNSError()
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: deletionError)
        }
    }
    
    func test_save_succeedsOnSuccessfullCacheInsertion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
     
    
    //MARK: Helper

    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void) {
        let exp = expectation(description: "Wait for expecation")
        
        var receivedError: Error?
        sut.save([uniqueItem()], completion: { error in
            receivedError = error
            exp.fulfill()
        })
        
        action()
        wait(for: [exp], timeout: 1.0)
         
        XCTAssertEqual(receivedError as NSError?, expectedError)
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
