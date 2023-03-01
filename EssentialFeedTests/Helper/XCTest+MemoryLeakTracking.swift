//
//  XCTest+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Lalit Bagga on 2023-02-22.
//

import XCTest

extension XCTestCase {
     func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
