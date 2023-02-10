//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-29.
//

import Foundation

public final class RemoteFeedLoader:FeedLoader {
    private let httpClient: HttpClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult<Error>
    
    public init(url: URL, httpClient: HttpClient) {
        self.httpClient = httpClient
        self.url = url
    }
    
    public func load(completion: @escaping (LoadFeedResult<Error>) -> Void) {
        httpClient.get(from: url, completion: { [weak self] response  in
            guard self != nil else { return }
            switch response {
            case .success(let data, let response):
                completion(FeedItemsMapper.map(data, response))
                
            case .failure(_):
                completion(.failure(.connectivity))
            }
        })
    }
}
