//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-26.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
