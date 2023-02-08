//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-26.
//

import Foundation

public struct FeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
    
}
