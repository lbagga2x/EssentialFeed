//
//  URLSessionHttpClientTests.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-02-10.
//

import XCTest
import EssentialFeed

class UrlSessionHttpClient {
    private let session: URLSession
    
    init(_ session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHttpClientTests: XCTestCase {
    
    func test_getUrl_resumeDataTaskWithURL() {
        let url = URL(string: "www.yahoo.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        
        let sut = UrlSessionHttpClient(session)
        
        sut.get(from: url, completion: { _ in })
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getUrl_failOnReuestError() {
        let url = URL(string: "www.yahoo.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        let error = NSError(domain: "This is error", code: -1)
        session.stub(url: url, task: task, error: error)
        
        let sut = UrlSessionHttpClient(session)
        
        let exp = expectation(description: "wait for test to finish")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError):
                XCTAssertEqual(receivedError as NSError, error)
                break
            default:
                XCTFail("Expected fauliure with error \(error) but got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: Helpers
    private class URLSessionSpy: URLSession {
        private var stubs = [URL: Stubs]()
        
        struct Stubs {
            let error: Error
            let dataTask: URLSessionDataTask
        }
        
        func stub(url: URL, task: URLSessionDataTask, error: Error = NSError(domain: "This is error", code: -1)) {
            stubs[url] = Stubs(error: error, dataTask: task)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Developer error no url found")
                
            }
            completionHandler(nil, nil, stub.error)
            return stub.dataTask ?? FakeURLSessionDataTask()
        }
        
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {
            
        }
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }
}
