//
//  ResultType.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation

public struct ResultType
{
    public let name: String
    public let fields: [(String, ResultValueType)]
    
    public init(name: String, fields: [(String, ResultValueType)])
    {
        self.name = name
        self.fields = fields
    }
}

public indirect enum ResultValueType
{
    case optional(ResultValueType)
    case array(ResultValueType)
    case structure(String)
    case float
    case int32
    case int
    case boolean
    case string
    case date
    case identifier
}
