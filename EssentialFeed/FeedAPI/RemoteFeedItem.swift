//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-03-16.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
