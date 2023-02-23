//
//  URLSessionHttpClientTests.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-02-10.
//

import XCTest
import EssentialFeed

class UrlSessionHttpClient: HttpClient {
    private let session: URLSession
    
    init(_ session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValueRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
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
        let url = anyURL()
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
       
        let error = NSError(domain: "This is error", code: -1)
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: error)
        
        XCTAssertEqual((receivedError! as NSError).domain, error.domain)
        XCTAssertEqual((receivedError! as NSError).code, error.code)
        
    }
    
    func test_getFromUrl_failsOnAllNilValues() {
        let receivedError = resultErrorFor(data: nil, response: nil, error: nil)
        XCTAssertNotNil(receivedError)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let anyData = anyData()
        let anyError = anyNSError()
        let nonHTTPURLResponse = nonHTTPURLResponse()
        let anyHTTPURLResponse = anyHTTPURLResponse()

        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        
        let resultValues = resultValuesFor(data: nil, response: response, error: nil)
        let emptyData = Data()
        XCTAssertEqual(resultValues?.data, emptyData)
        XCTAssertEqual(resultValues?.response.url, response.url)
        XCTAssertEqual(resultValues?.response.statusCode, response.statusCode)
    }
    
    //MARK: Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> UrlSessionHttpClient {
        let sut = UrlSessionHttpClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
        
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
       let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
//
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HttpClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        var  clientResult: HttpClientResult!
        let exp = expectation(description: "wait for test to completion")
        makeSUT().get(from: anyURL(), completion: { result in
            clientResult = result
            exp.fulfill()
        })
        wait(for: [exp], timeout: 1.0)
        return clientResult
    }
    
    private func anyURL() -> URL {
        return URL(string: "www.yahho.com")!
    }
    
    private func anyData() -> Data {
        return Data("any data".utf8)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stubs?
        private static var observe: ((URLRequest) -> Void)?
        
        private struct Stubs {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
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
