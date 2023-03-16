//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-26.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
