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
    func insert(_ feedItems: [LocalFeedImage], _ timestamp: Date, completion: @escaping InsertionCompletion)
    
    func retrieve()
}
