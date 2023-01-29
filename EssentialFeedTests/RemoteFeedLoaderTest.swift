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
    private let url: URL
    
    init(url: URL, httpClient: HttpClient) {
        self.httpClient = httpClient
        self.url = url
    }
    
    func load() {
        httpClient.get(from: url)
    }
}


final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        let url = URL(string: "www.yahho.com")!
        let client = HttpClientSpy()
        _ = RemoteFeedLoader(url: url, httpClient: client)
        
        XCTAssertNil(client.requestedUrl)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "www.yahho.com")!
        let client = HttpClientSpy()
        let loader = RemoteFeedLoader(url: url, httpClient: client)
        loader.load()
        
        XCTAssertEqual(url, client.requestedUrl)
    }
}
