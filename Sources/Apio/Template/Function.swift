//
//  Function.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation

public struct Function
{
    public let name: String
    public let documentationURL: String
    public let resultType: ResultType
    public let parameters: [Parameter]
    public let subDirectory: String? // The subdirectory to append to the base URL to get the complete URI for this function
    
    public init(name: String, documentationURL: String, resultType: ResultType, parameters: [Parameter], subDirectory: String? = nil)
    {
        self.name = name
        self.documentationURL = documentationURL
        self.resultType = resultType
        self.parameters = parameters
        self.subDirectory = subDirectory
    }
}
