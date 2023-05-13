//
//  Endpoint.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation

public struct Endpoint
{
    public let name: String // The Swifty name of this endpoint (used to generate struct names)
    public let subDirectory: String // The subdirectory to append to the base URL to get the complete URI for this endpoint
    public let documentationURL: String // The URL for this endpoint's documentation page
    public let functions: [Function] // Functions that can be created based on making requests to this endpoint
    public let errorResultType: ResultType?
    
    /// Creates a new Endpoint. An API can have one or more Endpoints.
    ///
    /// - Parameter name: The Swifty name of this endpoint (used to generate struct names) as a String
    /// - Parameter subDirectory: The subdirectory to append to the base URL to get the complete URI for this endpoint as a String
    /// - Parameter documentationURL: The URL for this endpoint's documentation page as a String
    /// - Parameter functions: Functions that can be created based on making requests to this endpoint
    public init(name: String, subDirectory: String, documentationURL: String, functions: [Function],  errorResultType: ResultType?)
    {
        self.name = name
        self.subDirectory = subDirectory
        self.documentationURL = documentationURL
        self.functions = functions
        self.errorResultType = errorResultType
    }
}
