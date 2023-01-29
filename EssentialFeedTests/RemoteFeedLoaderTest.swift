//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-01-29.
//

import XCTest

class HttpClient {
    var requestedUrl: URL?
}

class RemoteFeedLoader {
    
}

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        _ = RemoteFeedLoader()
        
        let client = HttpClient()
        
        XCTAssertNil(client.requestedUrl)
    }
}
