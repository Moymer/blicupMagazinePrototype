//
//  WebImageSearchBS.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

typealias CompletionHandlerWebImageSearch = (Result, query: String) -> Void

enum Result {
    case Success(AnyObject?)
    case Failure(NSError?)
}


// MARK: GIPHY

private let GIPHY_KEY = "XNRf204jKqaK4"
private let GIPHY_SERVICE_URL = "http://api.giphy.com/v1/gifs"
private let GIPHY_SEARCH_SERVICE_URL = "/search"
private let GIPHY_TRENDING_SERVICE_URL = "/trending"
private let GIPHY_LIMIT = 10

// MARK: GOOGLE
//blicup
private let GOOGLE_KEY = "AIzaSyB1PCncCceZmpyPn2gUqzE4GK2PK0AKjZI"
private let CSE = "013641101987360012027:uii2tslnxlm"

private let SIZE = "xxlarge"
private let TYPE = "image"
private let GOOGLE_SERVICE_URL = "https://www.googleapis.com/customsearch/v1"
private let FILETYPE = "jpeg"


enum GiphyKeys: String {
    case APIKEY = "api_key"
    case Query = "q"
    case LIMIT = "limit"
    case OFFSET = "offset"
}

enum GoogleKeys: String {
    case KEY = "key"
    case CSE = "cx"
    case TYPE = "searchType"
    case SIZE = "imgSize"
    case FILETYPE = "fileType"
    case Query = "q"
    case StartIndex = "start"
}


class WebImageSearchBS: NSObject {

    // MARK: Giphy Request
    
    class func fetchGiphyImagesForIndex(index: Int, andQuery query: String, trending: Bool, completionHandler: CompletionHandlerWebImageSearch) {
        
        let parameters:[String : AnyObject] = [GiphyKeys.APIKEY.rawValue : GIPHY_KEY,
                                               GiphyKeys.LIMIT.rawValue  : GIPHY_LIMIT,
                                               GiphyKeys.OFFSET.rawValue : index,
                                               GiphyKeys.Query.rawValue  : query]
        
        let serviceURL = trending ? GIPHY_TRENDING_SERVICE_URL : GIPHY_SEARCH_SERVICE_URL
        
        Alamofire.request(.GET, GIPHY_SERVICE_URL + serviceURL, parameters: parameters).responseJSON { response in
            
            switch response.result {
                
            case .Success:
                
                if let value = response.result.value {
                    
                    let json = JSON(value)
                    
                    if let items = json["data"].array {
                        let giphyImages = WebImageSearchBS.parseGiphyFetchedResults(items) as [WebImage]
                        completionHandler(Result.Success(giphyImages), query: query)
                    }
                }
                
            case .Failure(let error):
                completionHandler(Result.Failure(error), query: query)
            }
        }
    }
    
    
    class func parseGiphyFetchedResults(items: Array<JSON>) -> [WebImage] {
        
        var webImages:[WebImage] = []
        
        for item in items {
            
            let image = item["images"]["fixed_height_downsampled"]
            let imageBigSize = item["images"]["downsized"]
            
            if let height = image["height"].rawString(), width = image["width"].rawString(), imgUrl = image["url"].rawString(), imgUrlOriginal =  imageBigSize["url"].rawString() where !imgUrl.isEmpty && !imgUrlOriginal.isEmpty{
                
                let webImage = WebImage(tmbUrl: NSURL(string: imgUrl)!, imgUrl: NSURL(string: imgUrlOriginal)!)
                
                if let heightInt = NSNumberFormatter().numberFromString(height), widthInt = NSNumberFormatter().numberFromString(width) {
                    
                    webImage.height = CGFloat(heightInt)
                    webImage.width = CGFloat(widthInt)
                    
                    webImages.append(webImage)
                }
            }
        }
        
        return webImages
    }
    
    // MARK: Google Request
    
    class func fetchGoogleImagesForIndex(index: Int, andQuery query: String, completionHandler: CompletionHandlerWebImageSearch) {
        
        let parameters:[String : AnyObject] = [GoogleKeys.KEY.rawValue         : GOOGLE_KEY,
                                               GoogleKeys.CSE.rawValue         : CSE,
                                               GoogleKeys.TYPE.rawValue        : TYPE,
                                               GoogleKeys.SIZE.rawValue        : SIZE,
                                               GoogleKeys.FILETYPE.rawValue    : FILETYPE,
                                               GoogleKeys.Query.rawValue       : query,
                                               GoogleKeys.StartIndex.rawValue  : index]
        
        Alamofire.request(.GET, GOOGLE_SERVICE_URL, parameters: parameters).responseJSON { response in
            
            switch response.result {
                
            case .Success:
                
                if let value = response.result.value {
                    
                    let json = JSON(value)
                    
                    if let items = json["items"].array {
                         WebImageSearchBS.parseGoogleFetchedResults(items, completion: { (googleImages ) in
                            completionHandler(Result.Success(googleImages), query: query)
                        })
                       
                    } else if let request = json["queries"]["request"].array {
                        
                        if let results = request[0].dictionary {
                            if let totalResults = results["totalResults"] {
                                
                                if totalResults.intValue == 0 {
                                    completionHandler(Result.Success([]), query: query)
                                }
                            }
                        }
                    }
                    
                }
            case .Failure(let error):
                completionHandler(Result.Failure(error), query: query)
            }
        }
        
    }
    
    // Return result one by one after check url valifity
    class func parseGoogleFetchedResults(items: Array<JSON>, completion : ([WebImage]) -> Void ) ->  Void {
        

        var found : Bool = false
        var count = 0
        for item in items {
           
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                let imgUrl = item["link"].stringValue
                 count = count + 1
                if verifyURL(imgUrl)
                {
                   
                    found = true
                    let tmbUrl = item["image"]["thumbnailLink"].stringValue
                    let webImage = WebImage(tmbUrl: NSURL(string: tmbUrl)!, imgUrl: NSURL(string: imgUrl)!)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        completion([webImage])
                    })

                }
                if count == items.count && !found
                {
                    completion([])
                }

                
            })

        }

    }
    
    

    
    class func verifyURL(urlPath: String) -> Bool{
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(URL: url)
        request.timeoutInterval = 1
        request.HTTPMethod = "HEAD"
        var response: NSURLResponse?
        
        do {
            try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            
            if let httpResponse = response as? NSHTTPURLResponse {
                
                if httpResponse.statusCode != 200
                {
                    return false
                }
            }
        }
            
        catch  {
         
        }
        
        return true
     
    }
    

}


