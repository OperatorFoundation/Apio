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
    public let type: ValueType
    public let optional: Bool
    
    public init(name: String, description: String?, type: ValueType, optional: Bool)
    {
        self.name = name
        self.description = description
        self.type = type
        self.optional = optional
    }
}

public indirect enum ValueType
{
    case string
    case int32
    case boolean
    case array(ValueType)
    case structure(StructureType)
    
    var name: String
    {
        switch self
        {
            case .string:
                return "String"
            case .int32:
                return "Int32"
            case .boolean:
                return "Bool"
            case .array(let valueType):
                return "[\(valueType.name)]"
            case .structure(let structureType):
                return structureType.name
        }
    }
}

public struct StructureType
{
    public let name: String
    public let fields: [StructureProperty]
    
    public init(name: String, fields: [StructureProperty])
    {
        self.name = name
        self.fields = fields
    }
}

public struct StructureProperty
{
    public let name: String
    public let valueType: ValueType
    public let description: String?
    
    public init(name: String, valueType: ValueType, description: String? = nil)
    {
        self.name = name
        self.valueType = valueType
        self.description = description
    }
}
