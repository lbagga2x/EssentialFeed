//
//  URLSessionHttpClientTests.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-02-10.
//

import XCTest
import EssentialFeed

protocol HttpSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HttpSessionTask
}

protocol HttpSessionTask {
    func resume()
}

class UrlSessionHttpClient {
    private let session: HttpSession
    
    init(_ session: HttpSession) {
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
    private class URLSessionSpy: HttpSession {
        private var stubs = [URL: Stubs]()
        
        struct Stubs {
            let error: Error
            let dataTask: HttpSessionTask
        }
        
        func stub(url: URL, task: HttpSessionTask, error: Error = NSError(domain: "This is error", code: -1)) {
            stubs[url] = Stubs(error: error, dataTask: task)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HttpSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Developer error no url found")
                
            }
            completionHandler(nil, nil, stub.error)
            return stub.dataTask ?? FakeURLSessionDataTask()
        }
        
    }
    
    private class FakeURLSessionDataTask: HttpSessionTask {
        func resume() {
            
        }
    }
    
    private class URLSessionDataTaskSpy: HttpSessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
