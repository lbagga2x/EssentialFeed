//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-29.
//

import Foundation

public enum HttpClientResult {
    case success(HTTPURLResponse)
    case failure(Error)
}

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let httpClient: HttpClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, httpClient: HttpClient) {
        self.httpClient = httpClient
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        httpClient.get(from: url, completion: { response  in
            
            switch response {
            case .success(_):
                completion(.invalidData)
            case .failure(_):
                completion(Error.connectivity)
            }
           
        })
    }
}
