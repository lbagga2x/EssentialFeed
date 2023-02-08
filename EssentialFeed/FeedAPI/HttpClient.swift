//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-02-08.
//

import Foundation

public enum HttpClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
