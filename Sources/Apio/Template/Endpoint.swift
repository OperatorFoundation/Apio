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
    public let documentation: URL
    public let functions: [Function]
    
    public init(name: String, documentation: URL, functions: [Function])
    {
        self.name = name
        self.documentation = documentation
        self.functions = functions
    }
}
