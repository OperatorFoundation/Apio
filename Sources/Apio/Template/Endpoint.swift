//
//  Endpoint.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation

public struct Endpoint
{
    public let name: String
    public let documentationURLPath: String
    public let functions: [Function]
    
    public init(name: String, documentationURLPath: String, functions: [Function])
    {
        self.name = name
        self.documentationURLPath = documentationURLPath
        self.functions = functions
    }
}
