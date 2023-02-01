//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-01-26.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
