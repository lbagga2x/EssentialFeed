//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-04-04.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    

    func test_retrieve_deliversEmptyOnEmptyCache() {

        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversValueAfterInserting() {
        
        let sut = makeSUT()
        let item = uniqueImageFeed()
        let timestamp = Date.init()
        
        insert(sut, cache: (feed: item.local, timestamp: timestamp))
        expect(sut, toRetrieve: .found(feed: item.local, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let item = uniqueImageFeed()
        let timestamp = Date.init()
        
        insert(sut, cache: (feed: item.local, timestamp: timestamp))
        expect(sut, toRetrieveTwice: .found(feed: item.local, timestamp: timestamp))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        let item = uniqueImageFeed()
        let timestamp = Date.init()
        
        insert(sut, cache: (feed: uniqueImageFeed().local, timestamp: Date.init()))
        insert(sut, cache: (feed: item.local, timestamp: timestamp))
        expect(sut, toRetrieve: .found(feed: item.local, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT()
        try! "inavlid json".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_insert_failureOnInsertionError() {
        let sut = makeSUT(storeURL: URL(string: "corrupted_url"))
        let timestamp = Date.init()
     
        let insertionError = insert(sut, cache: (feed: uniqueImageFeed().local, timestamp: timestamp))
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for cache deletion")
        sut.deleteCacheFeed { deletionError in
            XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for cache deletion")
        sut.deleteCacheFeed { deletionError in
            XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        expect(sut, toRetrieve: .empty)
    }
    
    //MARK: HELPER
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let url = testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: (storeURL != nil) ? storeURL!: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func insert(_ sut: CodableFeedStore, cache: (feed: [LocalFeedImage], timestamp: Date)) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
       
        sut.insert(cache.feed, cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
                return insertionError
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
           
            switch (expectedResult, retrievedResult) {
                
            case (.empty, .empty), (.failure, .failure):
                break
                
            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(retrieved.feed, expected.feed, file: file, line: line)
                XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}

final class CodableFeedStore {
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    private struct Cache: Codable {
        let feedItems: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feedItems.map { $0.local}
        }
    }
    
    private struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let imageURL: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            imageURL = image.imageURL
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, imageURL: imageURL)
        }
    }
    
    func deleteCacheFeed(completion: @escaping FeedStore.DeletioCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        try! FileManager.default.removeItem(at: storeURL)
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let jsonDecoder = JSONDecoder()
        
        do {
            let cacheData = try jsonDecoder.decode(Cache.self, from: data)
            completion(.found(feed: cacheData.localFeed, timestamp: cacheData.timestamp))
        } catch {
            completion(.failure(error))
        }
      
       
    }
    
    func insert(_ feedItems: [LocalFeedImage], _ timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let codeableItems = feedItems.map(CodableFeedImage.init)
        let cache = Cache(feedItems: codeableItems, timestamp: timestamp)
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}


