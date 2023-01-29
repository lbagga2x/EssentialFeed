//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-01-29.
//

import XCTest

class HttpClient {
    static let shared = HttpClient()
    
    private init() {}
    
    var requestedUrl: URL?
}

class RemoteFeedLoader {
    func load() {
        HttpClient.shared.requestedUrl = URL(string: "www.yahho.com")
    }
}

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        _ = RemoteFeedLoader()
        
        XCTAssertNil(HttpClient.shared.requestedUrl)
    }
    
    func test_load_requestDataFromURL() {
        let loader = RemoteFeedLoader()
        loader.load()
        
        XCTAssertNotNil(HttpClient.shared.requestedUrl)
    }
}
