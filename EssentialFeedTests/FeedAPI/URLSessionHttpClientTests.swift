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
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = URL(string: "http://any-url.com")!
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observe { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getUrl_failOnReuestError() {
       
        let url = URL(string: "www.yahoo.com")!
        let error = NSError(domain: "This is error", code: -1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "wait for test to finish")
        makeSUT().get(from: url) { result in
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
        
    }
    
    //MARK: Helpers
    
    private func makeSUT() -> UrlSessionHttpClient {
        return UrlSessionHttpClient()
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stubs?
        private static var observe: ((URLRequest) -> Void)?
        
        private struct Stubs {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error) {
            stub = Stubs(data: data, response: response, error: error)
        }
        
        static func observe(_ observe: @escaping (URLRequest) -> Void) {
            self.observe = observe
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            observe = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            observe?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
           
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
