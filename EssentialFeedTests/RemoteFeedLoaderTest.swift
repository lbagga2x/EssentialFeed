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
        sut.load(completion: { _ in })
        
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_loadTwice_requestDataFromURL() {
        let url = URL(string: "www.yahho.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in })
        sut.load(completion: { _ in })
        XCTAssertEqual(client.requestedUrls, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
      
        expect(sut, toCompleteWithResult: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(withError: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        let (sut, client) = makeSUT()
        let status = [199, 201, 300, 400, 500]
   
        status.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HttpResponseWithInvalidData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .failure(.invalidData)) {
            let data = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: data)
        }
        
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(
                id: UUID(),
                description: nil,
                location: nil,
                imageURL: URL(string: "http://a-url.com")!)

            let item1JSON = [
                "id": item1.id.uuidString,
                "image": item1.imageURL.absoluteString
            ]

            let item2 = FeedItem(
                id: UUID(),
                description: "a description",
                location: "a location",
                imageURL: URL(string: "http://another-url.com")!)

            let item2JSON = [
                "id": item2.id.uuidString,
                "description": item2.description,
                "location": item2.location,
                "image": item2.imageURL.absoluteString
            ]

            let itemsJSON = [
                "items": [item1JSON, item2JSON]
            ]
        
        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load { capturedResult.append($0)}
       
        action()
       
        XCTAssertEqual(capturedResult, [result], file: file, line: line)
    }
    
    
    private func makeSUT(url: URL = URL(string: "www.yahho.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, httpClient: client)
        return (sut, client)
    }
    
    class HttpClientSpy: HttpClient {
     
        var requestedUrls:  [URL]  {
            return messages.map {$0.url}
        }
        
        private var messages = [(url: URL, completion: (HttpClientResult) -> Void)]()
          
        func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
            messages.append((url, completion))
           
        }
        
        func complete(withError error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0, data: Data = Data()) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
