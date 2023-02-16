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
    
    init(_ session: URLSession = .shared) {
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
    
 
    func test_getUrl_failOnReuestError() {
        URLProtocolStub.startInterceptingRequest()
        let url = URL(string: "www.yahoo.com")!
        let error = NSError(domain: "This is error", code: -1)
        URLProtocolStub.stub(url: url, error: error)
        
        let sut = UrlSessionHttpClient()
        
        let exp = expectation(description: "wait for test to finish")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError):
                XCTAssertEqual((receivedError as NSError).domain, error.domain)
                XCTAssertEqual((receivedError as NSError).code, error.code)
                break
            default:
                XCTFail("Expected fauliure with error \(error) but got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequest()
    }
    
    //MARK: Helpers
    private class URLProtocolStub: URLProtocol {
        private static var stubs = [URL: Stubs]()
        
        private struct Stubs {
            let error: Error?
        }
        
        static func stub(url: URL, error: Error = NSError(domain: "This is error", code: -1)) {
            stubs[url] = Stubs(error: error)
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return URLProtocolStub.stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
