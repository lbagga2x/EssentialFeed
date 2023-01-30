//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-29.
//

import Foundation

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (Error) -> Void)
}

public final class RemoteFeedLoader {
    private let httpClient: HttpClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
    }
    
    public init(url: URL, httpClient: HttpClient) {
        self.httpClient = httpClient
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void = { _ in }) {
        httpClient.get(from: url, completion: { error in
            completion(Error.connectivity)
        })
    }
}
