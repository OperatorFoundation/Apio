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
    public let documentation: URL
    public let resultType: ResultType
    public let parameters: [Parameter]
    
    public init(name: String, documentation: URL, resultType: ResultType, parameters: [Parameter])
    {
        self.name = name
        self.documentation = documentation
        self.resultType = resultType
        self.parameters = parameters
    }
}
