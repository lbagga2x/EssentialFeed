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
        let items: [RemoteFeedItem]
        
    }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData

        }
        return root.items
    }
}
