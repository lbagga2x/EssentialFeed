//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-03-27.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
