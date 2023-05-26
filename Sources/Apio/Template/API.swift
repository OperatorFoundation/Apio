// Created by Dr. Brandon Wiley
//

import Foundation

public struct API
{
    public let name: String
    public let url: String
    public let documentationURL: String
    public let resultTypes: [ResultType]
    public let structTypes: [StructureType]
    public let endpoints: [Endpoint]
    
    public init(name: String, url: String, documentationURL: String, resultTypes: [ResultType], structTypes: [StructureType], endpoints: [Endpoint])
    {
        self.name = name
        self.url = url
        self.documentationURL = documentationURL
        self.resultTypes = resultTypes
        self.structTypes = structTypes
        self.endpoints = endpoints
    }
    
    public enum AuthorizationType
    {
        // An example of a query item label would be like "token" used below to add an item called token
        // as well as a passed in value
        // URLQueryItem(name: "token", value: token)
        case urlQuery(queryItemLabel: String)
        
        // authorization label examples are "Bearer", "sso-key", etc.
        // this allows the generator to add a custom authorization header such as "Authorization: sso-key [API_KEY]:[API_SECRET]"
        // where [API_KEY]:[API_SECRET] would be read from a file
        case header(authorizationLabel: String)
    }
}
