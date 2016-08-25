//
//  LDTPMessageBuilder.swift
//  Blicup
//
//  Created by Moymer on 20/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation

class LDTPMessageBuilder: NSObject {
    //MARK: - Aux Functions
    
    class func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    class func bodyBuilder(parameters: [String: AnyObject]) -> NSData {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sort(<) {
            let value = parameters[key]!
            components += LDTPMessageBuilder.queryComponents(key, value)
        }
        let string = (components.map { "\($1)" } as [String]).joinWithSeparator("$")
        
        //print("Body: \(string)")
        return string.dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    class func bodyJsonBuilder(parameters: [String: AnyObject]) -> String {
       
        let data = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
        let string = String(data: data, encoding: NSUTF8StringEncoding)
        
        return string!
        
    }

    
    class internal func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: AnyObject] {
            
            
            let data = try! NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            //components.append((escape(key), escape("\(string)")))
            components.append(key,string!)
            
            
        } else if let array = value as? [AnyObject] {
            
            
            components.append(key,array.description)
            
            
            //WARNING: fdfdfdfd
            //for value in array {
            //   components += queryComponents("\(key)[]", value)
            //}
        } else {
            
            components.append( (key,"\(value)") )
            
            //components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    
    class internal func escape(string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
        
        var escaped = ""
        
        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinense characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================
        
        if #available(iOS 8.3, OSX 10.10, *) {
            escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex
            
            while index != string.endIndex {
                let startIndex = index
                let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
                let range = startIndex..<endIndex
                
                let substring = string.substringWithRange(range)
                
                escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring
                
                index = endIndex
            }
        }
        
        return escaped
    }
}

