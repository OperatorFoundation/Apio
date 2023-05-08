// Created by Dr. Brandon Wiley
//

import Foundation

public struct API
{
    public let name: String
    public let url: String
    public let documentationURL: String
    public let types: [ResultType]
    public let endpoints: [Endpoint]
    
    public init(name: String, url: String, documentationURL: String, types: [ResultType], endpoints: [Endpoint])
    {
        self.name = name
        self.url = url
        self.documentationURL = documentationURL
        self.types = types
        self.endpoints = endpoints
    }
}
