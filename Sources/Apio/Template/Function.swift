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
    public let errorResultType: ResultType?
    public let parameters: [Parameter]
    
    public init(name: String, documentationURL: String, resultType: ResultType, errorResultType: ResultType?, parameters: [Parameter])
    {
        self.name = name
        self.documentationURL = documentationURL
        self.resultType = resultType
        self.errorResultType = errorResultType
        self.parameters = parameters
    }
}
