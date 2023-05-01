//
//  Parameter.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation

public struct Parameter
{
    public let name: String
    public let description: String?
    public let type: ParameterType
    public let optional: Bool
    
    public init(name: String, description: String?, type: ParameterType, optional: Bool)
    {
        self.name = name
        self.description = description
        self.type = type
        self.optional = optional
    }
}
