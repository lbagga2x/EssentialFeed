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

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let exp = expectation(description: "wait for cache retrieval")
        
        let sut = CodableFeedStore()
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let exp = expectation(description: "wait for cache retrieval")
        
        let sut = CodableFeedStore()
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_deliversValueAfterInserting() {
        let exp = expectation(description: "wait for cache retrieval")
        
        let sut = CodableFeedStore()
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
}

final class CodableFeedStore {
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let jsonDecoder = JSONDecoder()
        let cacheData = try! jsonDecoder.decode(Cache.self, from: data)
        completion(.found(feed: cacheData.feedItems, timestamp: cacheData.timestamp))
    }
    
    func insert(_ feedItems: [LocalFeedImage], _ timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let cache = Cache(feedItems: feedItems, timestamp: timestamp)
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

struct Cache: Codable {
    let feedItems: [LocalFeedImage]
    let timestamp: Date
}
