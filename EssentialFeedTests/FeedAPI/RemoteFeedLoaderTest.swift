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
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, at: index, data: json)
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
        
        let item1 = makeItem(
                id: UUID(),
                description: nil,
                location: nil,
                imageURL: URL(string: "http://a-url.com")!)

         

            let item2 = makeItem(
                id: UUID(),
                description: "a description",
                location: "a location",
                imageURL: URL(string: "http://another-url.com")!)


           
        expect(sut, toCompleteWithResult: .success([item1.model, item2.model])) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_doesNotDeleiverResultAfterSUTInstanceDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = HttpClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, httpClient: client)
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { result in
            capturedResults.append(result)
        }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in 
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
       let exp = expectation(description: "wait for load completion")
        sut.load { receivedResult in
            switch(receivedResult, expectedResult) {
                
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems)
                
            case let (.failure(receivedError), .failure(receivedError)):
                XCTAssertEqual(receivedError, receivedError)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
       
        action()
       
        wait(for: [exp], timeout: 1.0)
    }
    
    
    private func makeSUT(url: URL = URL(string: "www.yahho.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, httpClient: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
                    "id": id.uuidString,
                    "description": description,
                    "location": location,
                    "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
            let json = ["items": items]
            return try! JSONSerialization.data(withJSONObject: json)
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
        
        func complete(withStatusCode code: Int, at index: Int = 0, data: Data) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
