//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Lalit Bagga on 2023-02-22.
//

import Foundation

public class UrlSessionHttpClient: HttpClient {
    private let session: URLSession
    
    public init(_ session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValueRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
            }
        }.resume()
    }
}
