//
//  Generate.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation
import Gardener

public func generate(api: API, target: String, resourcePath: String?, httpQuery: Bool) -> Bool
{
    let sourceDirectory = "Sources/\(target)"
    
    if File.exists(sourceDirectory)
    {
        guard File.delete(atPath: sourceDirectory) else
        {
            print("Failed to generate \(api.name) because a file already exists at \(sourceDirectory) and we were unable to delete it.")
            return false
        }
    }
    
    guard File.makeDirectory(atPath: sourceDirectory) else
    {
        print("Failed to generate \(api.name) because we were unable to create a directory at \(sourceDirectory).")
        return false
    }
    
    if let resourcePath
    {
        guard let resources = File.contentsOfDirectory(atPath: resourcePath) else
        {
            print("Failed to generate \(api.name) because we failed to read the contents of \(resourcePath).")
            return false
        }
        
        for resource in resources
        {
            let sourcePath = "\(resourcePath)/\(resource)"
            let destination = "\(sourceDirectory)/\(resource)"
            
            guard File.copy(sourcePath: sourcePath, destinationPath: destination) else
            {
                print("Failed to generate \(api.name) because we were unable to copy \(sourcePath) to \(destination).")
                return false
            }
        }
    }
    
    guard generateReadme(target: target, name: api.name, documentationURL: api.documentationURL) else
    {
        print("Failed to generate \(api.name) because we were unable to save the readme file to \(sourceDirectory).")
        return false
    }
    
    guard generateTypeFiles(target: target, types: api.types) else
    {
        print("Failed to generate \(api.name) because we were unable to generate a types file.")
        return false
    }
    
    for endpoint in api.endpoints
    {
        guard generateEndpoint(baseURL: api.url, target: target, endpoint: endpoint, httpQuery: httpQuery) else
        {
            print("Failed to generate endpoint \(endpoint.name)")
            return false
        }
    }
    
    print("API generation succeeded. Files saved to \(sourceDirectory)")
    
    return true
}

func generateReadme(target: String, name: String, documentationURL: String) -> Bool
{
    let readme = """
    
    A Swift wrapper for the \(name) API
    
    Documentation:
    \(documentationURL)
    """
    
    let destination = "Sources/\(target)/README.md"
    
    return File.put(destination, contents: readme.data)
}

func generateTypeFiles(target: String, types: [ResultType]) -> Bool
{
    let contentsResultTypes = generateTypes(types: types)
    
    let dateString = getCurrentDate()
    
    let contents = """
     //
     // Types.swift
     //
     // Generated by Apio on \(dateString)

     import Foundation

     \(contentsResultTypes)
     """

    let destination = "Sources/\(target)/Types.swift"

    return File.put(destination, contents: contents.data)
}

func generateTypes(types: [ResultType]) -> String
{
    let strings = types.map
    {
        resultType in
        
        return generateType(type: resultType)
    }
    
    return strings.joined(separator: "\n\n")
}

func generateType(type: ResultType) -> String
{
    let resultBody = generateResultBody(resultType: type)
    let resultInit = generateResultInit(resultType: type)

    let contents = """
    public struct \(type.name): Codable
    {
    \(resultBody)
    
    \(resultInit)
    }
    """

    return contents
}

func generateEndpoint(baseURL: String, target: String, endpoint: Endpoint, httpQuery: Bool) -> Bool
{
    let url = "\(baseURL)/\(endpoint.subDirectory)"
    
    guard let contentsFunctions = generateFunctions(baseURL: url, endpointName: endpoint.name, functions: endpoint.functions, httpQuery: httpQuery) else {return false}
    let contentsResultTypes = generateResultTypes(endpointName: endpoint.name, functions: endpoint.functions)

    let contents = """
     // \(endpoint.name).swift
     // \(endpoint.documentationURL)

     import Foundation

     \(contentsResultTypes)

     public struct \(endpoint.name)
     {
        public init() {}
     
        \(contentsFunctions)
     }
     """

    let destination = "Sources/\(target)/\(endpoint.name).swift"

    return File.put(destination, contents: contents.data)
}

func generateFunctions(baseURL: String, endpointName: String, functions: [Function], httpQuery: Bool) -> String?
{
    let strings = functions.map
    {
        function in
        
        return generateFunction(baseURL: baseURL, endpointName: endpointName, function: function, httpQuery: httpQuery)
    }
    
    return strings.joined(separator: "\n\n")
}

func generateFunction(baseURL: String, endpointName: String, function: Function, httpQuery: Bool) -> String
{
    let url = "\(baseURL)/\(function.name)"
    let parameters = generateParameters(parameters: function.parameters)
    let functionBody = generateFunctionBody(url: url, endpointName: endpointName, function: function, httpQuery: httpQuery)
    if (function.parameters.count == 0) {
        return """
            // \(function.documentationURL)
            public func \(function.name)(token: String) -> \(endpointName)\(function.resultType.name)Result?
            {
                \(functionBody)
            }
        """
    } else {
        return """
            // \(function.documentationURL)
            public func \(function.name)(token: String, \(parameters)) -> \(endpointName)\(function.resultType.name)Result?
            {
                \(functionBody)
            }
        """
    }
}

func generateParameters(parameters: [Parameter]) -> String
{
    let strings = parameters.map
    {
        parameter in

        generateParameter(parameter: parameter)
    }

    return strings.joined(separator: ", ")
}

func generateParameter(parameter: Parameter) -> String
{
    if parameter.optional {
        let contents = "\(parameter.name): \(parameter.type.rawValue)? = nil"
    
        return contents
    } else {
        let contents = "\(parameter.name): \(parameter.type.rawValue)"
    
        return contents
    }
}

func generateFunctionBody(url: String, endpointName: String, function: Function, httpQuery: Bool) -> String
{
    let request: String
    
    if httpQuery
    {
        request = generateHTTPQuery(url: url, function: function)
    }
    else
    {
        request = generateURLRequest(url: url, function: function)
    }

    let contents = """
            \(request)
    
            let dataString = String(decoding: resultData, as: UTF8.self)
            print("Result String: ")
            print(dataString)
    
            let decoder = JSONDecoder()
            \(generateResultDecoder(endpointName: endpointName, function: function))
    """

    return contents
}

func generateResultDecoder(endpointName: String, function: Function) -> String
{
    let decoderString: String
    
    if let errorResultType = function.errorResultType
    {
        decoderString =
        """
            if let result = try? decoder.decode(\(endpointName)\(function.resultType.name)Result.self, from: resultData)
            {
                return result
            }
            else if let errorResult = try? decoder.decode(\(endpointName)\(errorResultType.name)Result.self, from: resultData)
            {
                return errorResult
            }
            else
            {
                print("Expected a \(endpointName)\(function.resultType.name)Result or a \(endpointName)\(errorResultType.name)Result. Received an unexpected result instead: \\(resultData)")
                return nil
            }
        """
    }
    else
    {
        decoderString =
        """
            guard let result = try? decoder.decode(\(endpointName)\(function.resultType.name)Result.self, from: resultData) else
            {
                print("Failed to decode the result string to a \(endpointName)\(function.resultType.name)Result")
                return nil
            }

            return result
        """
    }
    
    return decoderString
}

// TODO: URL Request/Session
func generateURLRequest(url: String, function: Function) -> String
{
    let dictionaryContents = generateDictionaryContents(parameters: function.parameters)
    let contents =
    """
        guard var components = URLComponents(string: "\(url)") else
        {
            print("Failed to get components from \(url)")
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            \(dictionaryContents)
        ]

        guard let url = components.url else
        {
            print("Failed to resolve \\(components) to a URL")
            return nil
        }

        guard let resultData = try? Data(contentsOf: url) else
        {
            print("Failed to retrieve result data from \\(url)")
            return nil
        }
    """
    
    return contents
}

func generateHTTPQuery(url: String, function: Function) -> String
{
    let dictionaryContents = generateDictionaryContents(parameters: function.parameters)
    let contents =
    """
        guard var components = URLComponents(string: "\(url)") else
        {
            print("Failed to get components from \(url)")
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            \(dictionaryContents)
        ]

        guard let url = components.url else
        {
            print("Failed to resolve \\(components.url) to a URL")
            return nil
        }

        guard let resultData = try? Data(contentsOf: url) else
        {
            print("Failed to retrieve result data from \\(url)")
            return nil
        }
    """
    
    return contents
}

func generateDictionaryContents(parameters: [Parameter]) -> String
{
    let strings = parameters.map
    {
        parameter in

        return generateDictionaryPair(parameter: parameter)
    }

    return strings.joined(separator: ",\n\t\t")
}

func generateDictionaryPair(parameter: Parameter) -> String
{
    if parameter.optional
    {
        let value = generateValue(value: parameter)
        let contents = "URLQueryItem(name: \"\(parameter.name)\", value: \(value))"

        return contents
    }
    else
    {
        let value = generateValue(value: parameter)
        let contents = "URLQueryItem(name: \"\(parameter.name)\", value: \(value))"

        return contents
    }
}

func generateValue(value: Parameter) -> String
{
    if value.optional
    {
        switch value.type
        {
            case .string:
                return "\(value.name) ?? \"\""
            default:
                return "(\(value.name) == nil) ? \"\" : String(\(value.name)!)"
        }
    }
    else
    {
        switch value.type
        {
            case .boolean:
                return "String(\(value.name))"
            case .int32:
                return "String(\(value.name))"
            case .string:
                return "\(value.name)"
        }
    }
}

func generateResultTypes(endpointName: String, functions: [Function]) -> String
{
    // Create a result and error struct for each function in this endpoint
    let strings = functions.map
    {
        function in

        let resultType = generateResultType(endpointName: endpointName, resultType: function.resultType)
        
        if let errorResult = function.errorResultType
        {
            let errorResultType = generateResultType(endpointName: endpointName, resultType: errorResult)
            
            return ("\(resultType)\n\n\(errorResultType)")
        }
        else
        {
            return resultType
        }
    }

    return strings.joined(separator: "\n\n")
}

func generateResultType(endpointName: String, resultType: ResultType) -> String
{
    let resultBody = generateResultBody(resultType: resultType)
    let resultInit = generateResultInit(resultType: resultType)
    
    let contents = """
    public struct \(endpointName)\(resultType.name)Result: Codable
    {
    \(resultBody)
    
    \(resultInit)
    }
    """

    return contents
}

func generateResultBody(resultType: ResultType) -> String
{
    let strings = resultType.fields.map
    {
        (key, valueType) in
        
        return generateField(key: key, valueType: valueType)
    }
    
    return strings.joined(separator: "\n")
}

func generateResultInit(resultType: ResultType) -> String
{
    let parameters = generateInitParameters(parameters: resultType.fields)
    let functionBody = generateInitBody(resultType: resultType)
    
    if (resultType.fields.count == 0)
    {
        return """
            public init(token: String)
            {
        \(functionBody)
            }
        """
    }
    else
    {
        return """
            public init(token: String, \(parameters))
            {
        \(functionBody)
            }
        """
    }
}

func generateInitParameters(parameters: [(String, ResultValueType)]) -> String
{
    let strings = parameters.map
    {
        parameter in
        
        generateInitParameter(parameter: parameter)
    }
    
    return strings.joined(separator: ", ")
}

func generateInitParameter(parameter: (String, ResultValueType)) -> String
{
    let (name, type) = parameter
    let typeString = generateResultValueType(valueType: type)
    let contents = "\(name): \(typeString)"
    
    return contents
}

func generateInitBody(resultType: ResultType) -> String
{
    let strings = resultType.fields.map
    {
        (key, _) in
        
        return generateInitField(key: key)
    }
    
    return strings.joined(separator: "\n")
}

func generateInitField(key: String) -> String
{
    if key == "default" {
        return "\t\tself.`\(key)` = `\(key)`"
    } else {
        return "\t\tself.\(key) = \(key)"
    }
}

func generateField(key: String, valueType: ResultValueType) -> String
{
    let valueString = generateResultValueType(valueType: valueType)
    
    if key == "default"
    {
        return "\tpublic let `\(key)`: \(valueString)"
    }
    else
    {
        return "\tpublic let \(key): \(valueString)"
    }
}

func generateResultValueType(valueType: ResultValueType) -> String
{
    switch valueType
    {
        case .optional(let subType):
            let subTypeString = generateResultValueType(valueType: subType)
            return "\(subTypeString)?"
        case .array(let subType):
            let subTypeString = generateResultValueType(valueType: subType)
            return "[\(subTypeString)]"
        case .structure(let subType):
            return subType
        case .float:
            return "Float"
        case .int32:
            return "Int32"
        case .boolean:
            return "Bool"
        case .date:
            return "Date"
        case .string:
            return "String"
        case .identifier:
            return "String"
    }
}

func getCurrentDate() -> String
{
    let date = Date() // now
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    let dateString = formatter.string(from: date)
    
    return dateString
}
