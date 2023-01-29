//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-01-29.
//

import XCTest

protocol HttpClient {
    func get(from url: URL)
}

class HttpClientSpy: HttpClient {
    var requestedUrl: URL?
    
    func get(from url: URL) {
        requestedUrl = url
    }
}

class RemoteFeedLoader {
    private let httpClient: HttpClient
    
    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }
    
    func load() {
        httpClient.get(from: URL(string: "www.yahho.com")!)
    }
}


final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        let client = HttpClientSpy()
        _ = RemoteFeedLoader(httpClient: client)
        
        XCTAssertNil(client.requestedUrl)
    }
    
    func test_load_requestDataFromURL() {
        let client = HttpClientSpy()
        let loader = RemoteFeedLoader(httpClient: client)
        loader.load()
        
        XCTAssertNotNil(client.requestedUrl)
    }
}
