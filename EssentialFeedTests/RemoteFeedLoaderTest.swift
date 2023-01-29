//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-01-29.
//

import XCTest

class HttpClient {
    static var shared = HttpClient()
    
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
        HttpClient.shared.get(from: URL(string: "www.yahho.com")!)
    }
}

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        let client = HttpClientSpy()
        HttpClient.shared = client
        _ = RemoteFeedLoader()
        
        XCTAssertNil(HttpClient.shared.requestedUrl)
    }
    
    func test_load_requestDataFromURL() {
        let client = HttpClientSpy()
        HttpClient.shared = client
        let loader = RemoteFeedLoader()
        loader.load()
        
        XCTAssertNotNil(HttpClientSpy.shared.requestedUrl)
    }
}
