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
      
        expect(sut, toCompleteWithError: .connectivity) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(withError: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        let (sut, client) = makeSUT()
        let status = [199, 201, 300, 400, 500]
   
        status.enumerated().forEach { index, code in
            expect(sut, toCompleteWithError: .invalidData) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HttpResponseWithInvalidData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithError: .invalidData) {
            let data = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: data)
        }
        
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        var capturedError = [RemoteFeedLoader.Error]()
        sut.load { capturedError.append($0)}
       
        action()
       
        XCTAssertEqual(capturedError, [error], file: file, line: line)
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
