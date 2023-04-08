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
        let exp = expectation(description: "wait for cache retrieval")
        
        let sut = makeSUT()
        let item = uniqueImageFeed()
        let date = Date.init()
        sut.insert(item.local, date, completion: { _ in
           
            sut.retrieve { result in
                switch result {
                case .found(feed: let feed, timestamp: let timestamp):
                    XCTAssertEqual(feed, item.local)
                    XCTAssertEqual(timestamp, date)
                default:
                    XCTFail("Expected retrieving twice from empty cache to ")
                }
                
                exp.fulfill()
            }
            
        })
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let exp = expectation(description: "wait for cache retrieval")
        
        let sut = makeSUT()
        let item = uniqueImageFeed()
        let date = Date.init()
        sut.insert(item.local, date, completion: { _ in
           
            sut.retrieve { firstResult in
                
                sut.retrieve { secondResult in
                   
                    switch (firstResult, secondResult) {
                        
                    case let (.found(firsRound), .found(secoundRound)):
                        XCTAssertEqual(firsRound.feed, item.local)
                        XCTAssertEqual(firsRound.timestamp, date)
                        
                        XCTAssertEqual(secoundRound.feed, item.local)
                        XCTAssertEqual(secoundRound.timestamp, date)
                        
                    default:
                        XCTFail("Expected retrieving twice from non empty cache to deliver same found result with feed \(item.local) and timestamp \(date), got \(firstResult) and \(secondResult) instead")
                    }
                    exp.fulfill()
                }
            }
        })
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let exp = expectation(description: "wait for cache retrieval")
        
        let sut = makeSUT()
        let item = uniqueImageFeed()
        let timestamp = Date.init()
        sut.insert(uniqueImageFeed().local, Date.init(), completion: { _ in
           
            sut.insert(item.local, timestamp, completion: { _ in
                
                sut.retrieve { result in
                    switch result {
                    case .found(feed: let feed, timestamp: let timestamp):
                        XCTAssertEqual(feed, item.local)
                        XCTAssertEqual(timestamp, timestamp)
                    default:
                        XCTFail("Expected retrieving twice from empty cache to ")
                    }
                    
                    exp.fulfill()
                }
            })
        })
        

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT()
        try! "inavlid json".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    //MARK: HELPER
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let url = testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}


