//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-03-15.
//

import Foundation

public protocol FeedStore {
    typealias DeletioCompletion = (Error?)-> Void
    func deleteCacheFeed(completion: @escaping DeletioCompletion)
    
    typealias InsertionCompletion = (Error?)-> Void
    func insert(_ feedItems: [LocalFeedItem], _ timestamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalFeedItem: Equatable {
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
