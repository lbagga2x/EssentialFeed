//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-01-29.
//

import XCTest
import EssentialFeed
//SUT: System under test 
final class RemoteFeedLoaderTest: XCTestCase {
    // Method we are testing , Behaviour we expect
    func test_init_doesNotRequestDataFromUrl() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedUrls.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "www.yahho.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_loadTwice_requestDataFromURL() {
        let url = URL(string: "www.yahho.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        sut.load()
        XCTAssertEqual(client.requestedUrls, [url, url])
    }
    
    private func makeSUT(url: URL = URL(string: "www.yahho.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy){
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, httpClient: client)
        return (sut, client)
    }
    
    class HttpClientSpy: HttpClient {
        var requestedUrls = [URL]()
        
          func get(from url: URL) {
            requestedUrls.append(url)
        }
    }
}
