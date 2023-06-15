//
//  Generate.swift
//  
//
//  Created by Mafalda on 5/1/23. (Originally by Dr. Brandon Wiley)
//

import Foundation
import Gardener


// TODO: Don't delete all files in the directory we may have some that are not generated here
public func generate(api: API, target: String, authorizationType: API.AuthorizationType, resourcePath: String? = nil) -> Bool
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
    
    guard generateTypeFiles(target: target, resultTypes: api.resultTypes, structTypes: api.structTypes) else
    {
        print("Failed to generate \(api.name) because we were unable to generate a types file.")
        return false
    }
    
    for endpoint in api.endpoints
    {
        guard generateEndpoint(baseURL: api.url, target: target, endpoint: endpoint, authorizationType: authorizationType) else
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

func generateTypeFiles(target: String, resultTypes: [ResultType], structTypes: [StructureType]) -> Bool
{
    let contentsResultTypes = generateTypes(types: resultTypes)
    let contentsStructTypes = generateStructTypes(structs: structTypes)
    let dateString = getCurrentDate()
    
    let contents = """
     //
     // Types.swift
     //
     // Generated by Apio on \(dateString)

     import Foundation
     
     import Datable

     \(contentsResultTypes)
     \(contentsStructTypes)
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

func generateEndpoint(baseURL: String, target: String, endpoint: Endpoint, authorizationType: API.AuthorizationType) -> Bool
{
    let url: String
    
    if let subDirectory = endpoint.subDirectory
    {
        url = "\(baseURL)/\(subDirectory)"
    }
    else
    {
        url = "\(baseURL)"
    }
    
    let contentsResultTypes = generateResultTypes(endpoint: endpoint,
                                                  functions: endpoint.functions)
        
    guard let contentsFunctions = generateFunctions(baseURL: url,
                                                    endpoint: endpoint,
                                                    functions: endpoint.functions,
                                                    authorizationType: authorizationType) else {return false}
    
    let contentsErrors = generateErrorEnum(endpointName: endpoint.name, errorResultType: endpoint.errorResultType)

    let contents = """
     //
     // \(endpoint.name).swift
     // \(endpoint.documentationURL)
     //
     // Generated by Apio on \(getCurrentDate())

     import Foundation

     \(contentsResultTypes)

     public struct \(endpoint.name)
     {
        public init() {}
     
     \(contentsFunctions)
     }
     
     \(contentsErrors)
     """

    let destination = "Sources/\(target)/\(endpoint.name).swift"

    return File.put(destination, contents: contents.data)
}

func generateFunctions(baseURL: String, endpoint: Endpoint, functions: [Function], authorizationType: API.AuthorizationType) -> String?
{
    let strings = functions.map
    {
        function in
        
        return generateFunction(baseURL: baseURL, endpoint: endpoint, function: function, authorizationType: authorizationType)
    }
    
    return strings.joined(separator: "\n\n")
}

func generateFunction(baseURL: String, endpoint: Endpoint, function: Function, authorizationType: API.AuthorizationType) -> String
{
    var url: String
    
    if let subDirectory = function.subDirectory
    {
        url = "\(baseURL)/\(subDirectory)"
    }
    else
    {
        url = "\(baseURL)"
    }
    
    let resultTypeString = generateFunctionResultType(endpoint: endpoint, function: function)
    var functionParameters = [Parameter]()
    functionParameters.append(contentsOf: function.parameters)
    
    // If "$" is at the beginning of a url component, assume it needs to be a parameter
    // Update the URL so that it no longer contains the "$"
    if url.contains("$")
    {
        var urlParts = url.components(separatedBy: "/")
        
        for (index, urlPart) in urlParts.enumerated()
        {
            if urlPart.starts(with: "$")
            {
                let newParameterString = String(urlPart.dropFirst()).lowercased()
                urlParts[index] = "\\(\(newParameterString))"
                
                // FIXME: For now we will assume that any parameter provided in this way is a non-optional String
                let newParameter = Parameter(name: newParameterString, description: nil, type: .string, optional: false)
                functionParameters.append(newParameter)
            }
        }
        
        url = urlParts.joined(separator: "/")
    }
    
    let parameters = generateParameters(parameters: functionParameters)
    
    let functionBody = generateFunctionBody(url: url, endpoint: endpoint, function: function, authorizationType: authorizationType)
    
    if (functionParameters.count == 0)
    {
        switch authorizationType {
            case .urlQuery(_):
                return """
                    /// Documentation: \(function.documentationURL)
                    ///
                    public func \(function.name)(token: String) throws -> \(resultTypeString)
                    {
                    \(functionBody)
                    }
                """
            case .header(_): // Needs to be async
                return """
                    /// Documentation: \(function.documentationURL)
                    ///
                    public func \(function.name)(token: String) async throws -> \(resultTypeString)
                    {
                    \(functionBody)
                    }
                """
        }
    }
    else
    {
        switch authorizationType {
            case .urlQuery(_):
                return """
                    /// Documentation: \(function.documentationURL)
                    ///
                    public func \(function.name)(token: String, \(parameters)) throws -> \(resultTypeString)
                    {
                    \(functionBody)
                    }
                """
            case .header(_): // Needs to be async
                return """
                    /// Documentation: \(function.documentationURL)
                    ///
                    public func \(function.name)(token: String, \(parameters)) async throws -> \(resultTypeString)
                    {
                    \(functionBody)
                    }
                """
        }
    }
}

func generateFunctionResultType(endpoint: Endpoint, function: Function) -> String
{
    if let resultType = function.resultType
    {
        return "\(endpoint.name)\(resultType.name)Result"
    }
    else
    {
        return "Bool"
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
    if parameter.optional
    {
        let contents = "\(parameter.name): \(parameter.type.name)? = nil"
    
        return contents
    }
    else
    {
        let contents = "\(parameter.name): \(parameter.type.name)"
    
        return contents
    }
}

func generateFunctionBody(url: String, endpoint: Endpoint, function: Function, authorizationType: API.AuthorizationType) -> String
{
    let request: String
    let returnResultString: String
    
    if let resultType = function.resultType
    {
        returnResultString = generateResultDecoder(endpoint: endpoint, resultType: resultType)
    }
    else
    {
        returnResultString = generateReturnResult(authorizationType: authorizationType)
    }
    
    switch authorizationType
    {
        case .urlQuery(let queryItemLabel):
            request = generateURLQuery(endpointName: endpoint.name, url: url, function: function, authorizationLabel: queryItemLabel)
            
        case .header(let authorizationLabel):
            request = generateHTTPRequest(endpointName: endpoint.name, url: url, function: function, authorizationLabel: authorizationLabel)
    }

    let contents =
    """
        \(request)
            \(returnResultString)
    """

    return contents
}

func generateResultDecoder(endpoint: Endpoint, resultType: ResultType) -> String
{
    let decoderString: String
    
    if let errorResultType = endpoint.errorResultType
    {
        decoderString =
        """
        let decoder = JSONDecoder()
                if let result = try? decoder.decode(\(endpoint.name)\(resultType.name)Result.self, from: resultData)
                {
                    return result
                }
                else if let errorResult = try? decoder.decode(\(endpoint.name)\(errorResultType.name)Result.self, from: resultData)
                {
                    throw \(endpoint.name)Error.errorReceived(errorResult: errorResult)
                }
                else
                {
                    print("Expected a \(endpoint.name)\(resultType.name)Result or a \(endpoint.name)\(errorResultType.name)Result. Received an unexpected result instead: \\(resultData)")
                    throw \(endpoint.name)Error.unknownResultType(resultData: resultData)
                }
        """
    }
    else
    {
        decoderString =
        """
        let decoder = JSONDecoder()
                guard let result = try? decoder.decode(\(endpoint.name)\(resultType.name)Result.self, from: resultData) else
                {
                    print("Failed to decode the result string to a \(endpoint.name)\(resultType.name)Result")
                    throw \(endpoint.name)Error.unknownResultType(resultData: resultData)
                }

                return result
        """
    }
    
    return decoderString
}

func generateReturnResult(authorizationType: API.AuthorizationType) -> String
{
    switch authorizationType
    {
        case .urlQuery(_):
            return "return true" // FIXME: URL Queries must have a return type (throw?)
        case .header(_):
            let resultString =
            """
            let httpURLResponse = urlResponse as! HTTPURLResponse
                        return httpURLResponse.statusCode == 200
            """
            return resultString
    }
}

func generateHTTPRequest(endpointName: String, url: String, function: Function, authorizationLabel: String) -> String
{
    let requestValues = generateRequestURLValues(parameters: function.parameters)
    var setHTTPMethod = ""
    
    if let method = function.httpMethod
    {
        setHTTPMethod =
        """
        
                request.httpMethod = "\(method)"
        
        """
    }
    
    let contents =
    """
    let requestURLString = "\(url)"
            
            guard let requestURL = URL(string: requestURLString) else
            {
                print("Failed to \(url) to a valid URL")
                throw \(endpointName)Error.invalidRequestURL(url: requestURLString)
            }
            
            var request = URLRequest(url: requestURL)
            request.setValue("\(authorizationLabel) \\(token)", forHTTPHeaderField: "Authorization")
            \(requestValues)
            \(setHTTPMethod)
            let (resultData, urlResponse) = try await URLSession.shared.data(for: request)
    """
    
    return contents
}


func generateURLQuery(endpointName: String, url: String, function: Function, authorizationLabel: String) -> String
{
    let dictionaryContents = generateDictionaryContents(parameters: function.parameters)
    let contents =
    """
    let requestURL = "\(url)"
    
        guard var components = URLComponents(string: "\(url)") else
        {
            print("Failed to get components from \(url)")
            throw \(endpointName)Error.invalidRequestURL(url: requestURL)
        }

        components.queryItems = [
            URLQueryItem(name: "\(authorizationLabel)", value: token),
            \(dictionaryContents)
        ]

        guard let url = components.url else
        {
            print("Failed to resolve \\(components.url) to a URL")
            throw \(endpointName)Error.invalidRequestURL(url: requestURL)
        }

        let resultData = try Data(contentsOf: url)
    """
    return contents
}

func generateRequestURLValues(parameters: [Parameter]) -> String
{
    let strings = parameters.map
    {
        parameter in
        
        return generateRequestURLValue(parameter: parameter)
    }
    
    return strings.joined(separator: "\n")
}

func generateRequestURLValue(parameter: Parameter) -> String
{
    let contents: String
    
    switch parameter.type
    {
        case .structure(_):
            contents =
            """
            
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let requestBody = try encoder.encode(\(parameter.name))
                    
                    request.httpBody = requestBody
            """
        case .array(_):
            contents =
            """
            
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let requestBody = try encoder.encode(\(parameter.name))
                    
                    request.httpBody = requestBody
            """
        default:
            let value = generateValue(value: parameter)
            contents = "\t\trequest.setValue(\(value), forHTTPHeaderField: \"\(parameter.name)\")"
    }
    
    return contents
}

func generateDictionaryContents(parameters: [Parameter]) -> String
{
    let strings = parameters.map
    {
        parameter in

        return generateDictionaryPair(parameter: parameter)
    }

    return strings.joined(separator: ",\n\t\t\t")
}

func generateDictionaryPair(parameter: Parameter) -> String
{
    let value = generateValue(value: parameter)
    let contents = "URLQueryItem(name: \"\(parameter.name)\", value: \(value))"

    return contents
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
                return value.name
            case .array(let subType):
                let subTypeString = subType.name
                return "[\(subTypeString)]"
            case .structure(_):
                return value.name
        }
    }
}

func generateResultTypes(endpoint: Endpoint, functions: [Function]) -> String
{
    // Create a result and error struct for each function in this endpoint
    var strings = [String]()
    for function in functions
    {
        if let resultType = function.resultType
        {
            strings.append(generateResultType(endpointName: endpoint.name, resultType: resultType))
        }
    }
    
    if let errorResult = endpoint.errorResultType
    {
        let errorResultType = generateResultType(endpointName: endpoint.name, resultType: errorResult)
        strings.append(errorResultType)
    }
    
    if strings.isEmpty
    {
        return ""
    }
    else
    {
        return strings.joined(separator: "\n\n")
    }
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

func generateParameterTypes(endpoint: Endpoint) -> String
{
    var parameterStructs = [StructureType]()
    
    for function in endpoint.functions
    {
        for parameter in function.parameters
        {
            switch parameter.type
            {
                case .structure(let structureType):
                    parameterStructs.append(structureType)
                default:
                    continue
            }
        }
    }
    
    if !parameterStructs.isEmpty
    {
        return generateStructTypes(structs: parameterStructs)
    }
    else
    {
        return ""
    }
}

func generateStructTypes(structs: [StructureType]) -> String
{
    let strings = structs.map
    {
        structure in
        
        return generateParameterType(parameterStructureType: structure)
    }
    
    return strings.joined(separator: "\n\n")
}

func generateParameterType(parameterStructureType: StructureType) -> String
{
    let structDocumentation = generateStructDocumentation(structType: parameterStructureType)
    let structBody = generateStructBody(structType: parameterStructureType)
    let structInit = generateStructInit(structType: parameterStructureType)
    
    let contents = """
    /// \(parameterStructureType.name)
    ///
    public struct \(parameterStructureType.name): Codable
    {
    \(structBody)
    
        /// Creates a new instance from the given arguments.
    \(structDocumentation)
    \(structInit)
    }
    """

    return contents
}

func generateStructDocumentation(structType: StructureType) -> String
{
    var strings = [String]()
    
    for field in structType.fields
    {
        if let note = field.description
        {
            let comment = "\t/// - Parameter \(field.name): \(note)"
            strings.append(comment)
        }
    }
    
    if strings.isEmpty
    {
        return "\t///"
    }
    else
    {
        let documentationString =
        """
            ///
        \(strings.joined(separator: "\n"))
        """
        
        return documentationString
    }
}

func generateStructBody(structType: StructureType) -> String
{
    let strings = structType.fields.map
    {
        structureProperty in
        
        generateStructField(structProperty: structureProperty)
    }
    
    return strings.joined(separator: "\n")
}

func generateStructInit(structType: StructureType) -> String
{
    let parameters = generateStructInitParameters(parameters: structType.fields)
    let functionBody = generateStructInitBody(structType: structType)
    
    if (structType.fields.count == 0)
    {
        return """
            public init()
            {
            \(functionBody)
            }
        """
    }
    else
    {
        return """
            public init(\(parameters))
            {
            \(functionBody)
            }
        """
    }
}

func generateStructInitParameters(parameters: [StructureProperty]) -> String
{
    let strings = parameters.map
    {
        parameter in
        
        generateStructInitParameter(parameter: parameter)
    }
    
    return strings.joined(separator: ", ")
}

func generateStructInitParameter(parameter: StructureProperty) -> String
{
    let typeString = generateStructValueType(valueType: parameter.valueType)
    let contents = "\(parameter.name): \(typeString)"
    
    return contents
}

func generateStructInitBody(structType: StructureType) -> String
{
    let strings = structType.fields.map
    {
        parameter in
        
        return generateStructInitField(name: parameter.name)
    }
    
    return strings.joined(separator: "\n")
}

func generateStructInitField(name: String) -> String
{
    return "\t\tself.\(name) = \(name)"
}

func generateStructField(structProperty: StructureProperty) -> String
{
    let valueString = generateStructValueType(valueType: structProperty.valueType)
    return "\tpublic let \(structProperty.name): \(valueString)"
}

func generateStructValueType(valueType: ValueType) -> String
{
    switch valueType
    {
        case .array(let subType):
            let subTypeString = subType.name
            return "[\(subTypeString)]"
        case .structure(let subType):
            return subType.name
        case .int32:
            return "Int32"
        case .boolean:
            return "Bool"
        case .string:
            return "String"
//        case .float:
//            return "Float"
//        case .date:
//            return "Date"
//        case .identifier:
//            return "String"
// TODO: Optional Case
//        case .optional(let subType):
//            let subTypeString = generateResultValueType(valueType: subType)
//            return "\(subTypeString)?"
    }
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
    if key == "default"
    {
        return "\t\tself.`\(key)` = `\(key)`"
    }
    else
    {
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
        case .int64:
            return "Int64"
    }
}

func generateErrorEnum(endpointName: String, errorResultType: ResultType?) -> String
{
    let errorEnumString =
    """
    public enum \(endpointName)Error: Error
    {
    \(generateErrorCases(endpointName: endpointName, errorResultType: errorResultType))
    }
    """
    
    return errorEnumString
}

func generateErrorCases(endpointName: String, errorResultType: ResultType?) -> String
{
    let errorCasesString: String
    
    if let errorResult = errorResultType
    {
        errorCasesString =
        """
            case invalidRequestURL(url: String)
            case unknownResultType(resultData: Data)
            case errorReceived(errorResult: \(endpointName)\(errorResult.name)Result)
        """
    }
    else
    {
        errorCasesString =
        """
            case invalidRequestURL(url: String)
            case unknownResultType(resultData: Data)
        """
    }
    
    return errorCasesString
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
