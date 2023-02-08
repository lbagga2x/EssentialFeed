//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-29.
//

import Foundation

public final class RemoteFeedLoader {
    private let httpClient: HttpClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, httpClient: HttpClient) {
        self.httpClient = httpClient
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        httpClient.get(from: url, completion: { response  in
            
            switch response {
            case .success(let data, let response):
                completion(FeedItemsMapper.map(data, response))
                
            case .failure(_):
                completion(.failure(.connectivity))
            }
        })
    }
    
//    private func map(data: Data, response: HTTPURLResponse) -> Result {
//        do {
//            let items = try FeedItemsMapper.map(data, response)
//            return .success(items)
//        } catch {
//            return.failure(.invalidData)
//        }
//    }
}
