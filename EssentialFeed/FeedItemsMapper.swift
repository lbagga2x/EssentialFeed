//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-02-08.
//

import Foundation

internal final class FeedItemsMapper {
    static var OK_200: Int { return 200 }
    
    private struct Root: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            return items.map { $0.item }
        }
    }
    
    private struct Item: Decodable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
            
        }
        return .success(root.feed)
    }
}
