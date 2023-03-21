//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-03-21.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    private var deletionCompletions = [DeletioCompletion]()
    
    
    private var insertionCompletions = [InsertionCompletion]()
    
    enum ReceivedMessage: Equatable {
        case insert([LocalFeedImage],Date)
        case deleteCacheFeed
    }
    var receivedMesseges = [ReceivedMessage]()
    
    func deleteCacheFeed(completion: @escaping (Error?)-> Void) {
        deletionCompletions.append(completion)
        receivedMesseges.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
       deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feedItems: [LocalFeedImage], _ timestamp: Date, completion: @escaping (Error?)-> Void) {
        insertionCompletions.append(completion)
        receivedMesseges.append(.insert(feedItems, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
