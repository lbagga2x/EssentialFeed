//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-01-29.
//

import XCTest

class HttpClient {
    static var shared = HttpClient()
    
    private init() {}
    
    var requestedUrl: URL?
    
    func get(from url: URL) {}
}

class HttpClientSpy: HttpClient {
    override func get(from url: URL) {
        requestedUrl = url
    }
}

class RemoteFeedLoader {
    func load() {
        HttpClientSpy.shared.requestedUrl = URL(string: "www.yahho.com")
    }
}

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        _ = RemoteFeedLoader()
        
        XCTAssertNil(HttpClientSpy.shared.requestedUrl)
    }
    
    func test_load_requestDataFromURL() {
        let loader = RemoteFeedLoader()
        loader.load()
        
        XCTAssertNotNil(HttpClientSpy.shared.requestedUrl)
    }
}
