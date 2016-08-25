//
//  AmazonManager.swift
//  Blicup
//
//  Created by Gustavo Tiago on 18/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import AWSS3
import AWSSNS
import Kingfisher

enum ImageContentType: String {
    case PNG = "png"
    case GIF = "gif"
    case JPEG = "jpeg"
}

let SUPERIOR_IMAGE_SIZE_LIMIT  = 200
let INFERIOR_IMAGE_SIZE_LIMIT  = 60

let SUPERIOR_THUMB_IMAGE_SIZE_LIMIT  = 50
let INFERIOR_THUMB_IMAGE_SIZE_LIMIT  = 20

class AmazonManager: NSObject {
    
    
    private static let cognitoPoolId = "us-east-1:25bbb8ab-e2c6-4188-bd69-b3ffd06627b8"
    private static let bucket = "blicup"
    private static let bucket_chat_html = "blicup.com/chat"
    
    // PRODUCAO
    // private static let SNSPlatformApplicationArn = "arn:aws:sns:us-east-1:205389097341:app/APNS/BlicupProd"
    
    // DEV -- Use this!
    private static let SNSPlatformApplicationArn = "arn:aws:sns:us-east-1:205389097341:app/APNS_SANDBOX/BlicupDev"
   
    private static let AMAZON_S3_HTML_BASE = "https://blicup.com/chat/"
    internal static let AMAZON_S3_BASE = "https://blicup.s3.amazonaws.com/"
    internal static let AMAZON_S3_BASE_THUMB = "https://blicup.s3.amazonaws.com/thumb_"
    
    private static let blicup_fb_id = "1060740370614401"
    private static let blicup_appstore_name = "blicup"
    private static let blicup_appstore_id = "1096602524"

    
    /*
     Exemplo token Twitter
     let token = unwrappedSession.authToken + ";" + unwrappedSession.authTokenSecret
     
     Exemplo token Facebook
     let token = FBSDKAccessToken.currentAccessToken().tokenString
     
     Criando credenciais AWS
     AmazonManager().setCredentialsWithFacebook(token)
     */
    
    class func setCredentialsWithFacebook(token: String) {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:cognitoPoolId)
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        configuration.timeoutIntervalForResource = 30
        
        credentialsProvider.logins = [AWSCognitoLoginProviderKey.Facebook.rawValue: token]
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    }
    
    class func setCredentialsWithTwitter(token: String) {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:cognitoPoolId)
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        configuration.timeoutIntervalForResource = 30
        
        credentialsProvider.logins = [AWSCognitoLoginProviderKey.Twitter.rawValue: token]
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    }
    
    
    internal class func getThumbUrlFromMainUrl(url : String) -> String
    {
       let fileExt  = (url as NSString).pathExtension
        if fileExt != ImageContentType.GIF.rawValue {
            return url.stringByReplacingOccurrencesOfString(AMAZON_S3_BASE, withString: AMAZON_S3_BASE_THUMB)
        }
        else{
            return url
        }
    }
    
    private class func saveImage(image: UIImage, path: String?, thumbPath: String?, imageContentType: String) -> Bool{
        
        if imageContentType == ImageContentType.GIF.rawValue && path != nil{
            
            let gifImageData = UIImage.ImageGIFRepresentation(image, duration: 0.0, repeatCount: 0)
            let result = gifImageData!.writeToFile(path!, atomically: true)
            return result
            
        } else {
            
            var compression : (NSData,CGFloat)? = nil
            var result: Bool = true
            if(path != nil )
            {
                compression = getImageCompression(image, compression: 0.5, inferiorLimit: INFERIOR_IMAGE_SIZE_LIMIT, superiorLimit: SUPERIOR_IMAGE_SIZE_LIMIT)
                let jpegImageData = compression!.0
                result = jpegImageData.writeToFile(path!, atomically: true)
            }
            if thumbPath != nil && result
            {
                var thumbCompressionFactor: CGFloat = 0.3
                if compression != nil
                {
                    thumbCompressionFactor = compression!.1/3
                }
                
                let compressionThumb = getImageCompression(image, compression: thumbCompressionFactor, inferiorLimit: INFERIOR_THUMB_IMAGE_SIZE_LIMIT, superiorLimit: SUPERIOR_THUMB_IMAGE_SIZE_LIMIT)
                let jpegImageDataThumb = compressionThumb.0
                result = result && jpegImageDataThumb.writeToFile(thumbPath!, atomically: true)
            }

            return result
        }
        
    }
    
    
    private class func getImageCompression(image: UIImage,compression: CGFloat, inferiorLimit : Int, superiorLimit :  Int  ) -> (NSData,CGFloat)
    {
        var diff : CGFloat = 0.0
        let jpegImageData = UIImageJPEGRepresentation(image,compression)
        
        let imgSizeKB = (jpegImageData?.length)!/1000
        
        if imgSizeKB > superiorLimit
        {
            diff = -0.05
        }
        else
            if imgSizeKB < inferiorLimit
            {
                diff = +0.05
            }
        
        
        if diff != 0.0 && compression > 0.1 && compression <= 1.0
        {
            return getImageCompression(image, compression: compression+diff, inferiorLimit: inferiorLimit, superiorLimit: superiorLimit)
        }
        else
        {
            //print("image Size (KB): \((jpegImageData?.length)!/1000)")
            return (jpegImageData!,compression)
        }
        
    }
    
    
    
    private class func getDocumentsURL() -> NSURL {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        return documentsURL
    }
    
    private class func fileInDocumentsDirectory(filename: String) -> String {
        let fileURL = getDocumentsURL().URLByAppendingPathComponent(filename)
        return fileURL.path!
        
    }
    
    class func uploadHTMLToAmazonBucket(dictionary: NSDictionary, key: String, completionHandler: (urlFile: String?) -> ()){
        
        let htmlFileData: NSData = self.createHTMLDocument(dictionary).dataUsingEncoding(NSUTF8StringEncoding)!
        let filePath = self.fileInDocumentsDirectory(key.stringByAppendingString(".html"))
        htmlFileData.writeToFile(filePath, atomically: true)
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.contentType = "text/html"
        uploadRequest.body =  NSURL(fileURLWithPath: filePath)
        uploadRequest.key = key.stringByAppendingString(".html")
        uploadRequest.bucket = bucket_chat_html
        self.uploadToBlicupSite(uploadRequest, path: filePath) { (url) in
            completionHandler(urlFile: url)
        }
    }
    
    class func uploadImageToAmazonBucket(image: UIImage, key: String, completionHandler: (urlImagem: String?) -> ()){
        
        let imageData: NSData = UIImagePNGRepresentation(image)!
        let md5 = imageData.MD5() as String
        let key = key + "_" + md5
        
        let contentType = image.images != nil ? ImageContentType.GIF.rawValue : ImageContentType.JPEG.rawValue
        
        let filePath = self.fileInDocumentsDirectory(key.stringByAppendingString("." + contentType))
        self.saveImage(image, path: nil,thumbPath: filePath, imageContentType: contentType)
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.contentType = "image/" + contentType
        uploadRequest.body =  NSURL(fileURLWithPath: filePath)
        uploadRequest.key = key.stringByAppendingString("." + contentType)
        uploadRequest.bucket = bucket
        self.upload(uploadRequest, path: filePath) { (url) in
            completionHandler(urlImagem: url)
        }
    }

    
    class func uploadMultipleImagesToAmazonBucket(images: [UIImage], key: String, completionHandler: (urlImages: [String]?) -> ()) {
        
        var tasks: [AWSTask] = []
        var paths: [String] = []
        var urlKeys: [String] = []
        var uploads: [AWSS3TransferManagerUploadRequest] = []
        
        for image in images {
            
            let imageData = UIImagePNGRepresentation(image)!
            let md5 = imageData.MD5() as String
            let key = key + "_" + md5
            
            let contentType = image.images != nil ? ImageContentType.GIF.rawValue : ImageContentType.JPEG.rawValue
            
            let fileName = key.stringByAppendingString("." + contentType)
            let filePath = self.fileInDocumentsDirectory(fileName)
            
            let thumbName = "thumb_".stringByAppendingString(key.stringByAppendingString("." + contentType))
            let thumbPath = self.fileInDocumentsDirectory(thumbName)
            self.saveImage(image, path: filePath,thumbPath: thumbPath, imageContentType: contentType)
            
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest.contentType = "image/" + contentType
            uploadRequest.body =  NSURL(fileURLWithPath: filePath)
            uploadRequest.key = fileName
            uploadRequest.bucket = bucket
            uploads.append(uploadRequest)
            paths.append(filePath)
            
            if ImageContentType.GIF.rawValue !=  contentType
            {
                let uploadRequestThumb = AWSS3TransferManagerUploadRequest()
                uploadRequestThumb.contentType = "image/" + contentType
                uploadRequestThumb.body =  NSURL(fileURLWithPath: thumbPath)
                uploadRequestThumb.key = thumbName
                uploadRequestThumb.bucket = bucket
                uploads.append(uploadRequestThumb)
                paths.append(thumbPath)
            }
            
            urlKeys.append("\(AMAZON_S3_BASE)\(uploadRequest.key!)")
        }
        
        uploads = removeUploadDuplicates(uploads)
        
        tasks = uploads.map({(uploadRequest) -> AWSTask in
            let task = AWSS3TransferManager.defaultS3TransferManager().upload(uploadRequest)
            return task
        })
        
        paths.unique()
        
        AWSTask(forCompletionOfAllTasksWithResults: tasks).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (taskResult) -> AnyObject? in
           // print(taskResult)
            if taskResult.error == nil {
                
                completionHandler(urlImages: urlKeys)
                
                //delete file out of mai thread
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    for index in 0...(paths.count - 1) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(paths[index])
                        }
                        catch let error as NSError {
                            print("Erro ao deletar: \(error)")
                        }
                    }
                    
                })
            }
            else{
                completionHandler(urlImages: nil)
            }
            return nil
        })
    }
    
    class func removeUploadDuplicates(uploads: [AWSS3TransferManagerUploadRequest]) -> [AWSS3TransferManagerUploadRequest]{
        var uploadWithoutDuplicates: [AWSS3TransferManagerUploadRequest] = []
        for objectUpload in uploads{
            for objectUploadAux in uploads{
                if objectUploadAux.key! == objectUpload.key!{
                    let resultPredicate = NSPredicate(format: "key contains[c] %@", objectUpload.key!)
                    let aux = uploadWithoutDuplicates.contains{resultPredicate.evaluateWithObject($0)}
                    if !aux{
                       uploadWithoutDuplicates.append(objectUploadAux)
                    }
                }
            }
        }
        return uploadWithoutDuplicates
    }
    
    
    
    class func downloadImageFromAmazonBucket(userImageKey: String){
        let downloadingFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(userImageKey)
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = bucket
        downloadRequest.key = userImageKey.stringByAppendingString(".png")
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        transferManager.download(downloadRequest).continueWithBlock({ (task) -> AnyObject! in
            if task.error != nil{
                print("download failed: \(task.error!)")
            } else {
                print("download completed")
                if let data = NSData(contentsOfURL: downloadingFileURL){
                    if UIImage(data: data) != nil{
                        print("imagem ok")
                    }
                }
            }
            return nil
        })
        
    }
    
    private class func uploadToBlicupSite(uploadRequest: AWSS3TransferManagerUploadRequest, path: String, completionHandler: (url: String?) -> ()) {
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if task.error != nil{
                print("upload failed: \(task.error!.code)")
                completionHandler(url: nil)
            }
            else{
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                }
                catch let error as NSError {
                    print("Erro ao deletar: \(error)")
                }
                
                 completionHandler(url:  "\(AMAZON_S3_HTML_BASE)\(uploadRequest.key!)")
   
                //print("upload completed")
            }
            return nil
        }
    }
    
    private class func upload(uploadRequest: AWSS3TransferManagerUploadRequest, path: String, completionHandler: (url: String?) -> ()) {
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if task.error != nil{
                print("upload failed: \(task.error!.code)")
                completionHandler(url: nil)
            }
            else{
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                }
                catch let error as NSError {
                    print("Erro ao deletar: \(error)")
                }
                
                completionHandler(url:  "\(AMAZON_S3_BASE)\(uploadRequest.key!)")

                //print("upload completed")
            }
            return nil
        }
    }

    
    private class func getPreSignedURL(imageKey: String,  completionHandler: (error: Bool, url: String?) -> ()){
        let awss3URLRequest = AWSS3GetPreSignedURLRequest()
        awss3URLRequest.key = imageKey
        awss3URLRequest.bucket = bucket
        awss3URLRequest.HTTPMethod = AWSHTTPMethod.GET
        awss3URLRequest.expires = NSDate(timeIntervalSinceNow: 3600)
        
        AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(awss3URLRequest).continueWithBlock { (task) -> AnyObject? in
            if (task.error != nil){
                completionHandler(error: true, url: nil)
            }
            else{
                let urlResult = task.result?.URLString
                let string = urlResult!
                if let range = string.rangeOfString("?") {
                    let firstPart = string[string.startIndex..<range.startIndex]
                    completionHandler(error: false, url: firstPart)
                }
                else {
                    completionHandler(error: true, url: nil)
                }
            }
            return nil
        }
    }
    
    private class func getPreSignedURLForMultiplesImages(imageKeys: [String],  completionHandler: (error: Bool, urls: [String]?) -> ()){
        
        var tasks: [AWSTask] = []
        
        for imageKey in imageKeys{
            let awss3URLRequest = AWSS3GetPreSignedURLRequest()
            awss3URLRequest.key = imageKey
            awss3URLRequest.bucket = bucket
            awss3URLRequest.HTTPMethod = AWSHTTPMethod.GET
            awss3URLRequest.expires = NSDate(timeIntervalSinceNow: 3600)
            let task = AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(awss3URLRequest)
            tasks.append(task)
        }
        
        AWSTask(forCompletionOfAllTasksWithResults: tasks).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (taskResult) -> AnyObject? in
            if (taskResult.error != nil){
                completionHandler(error: true, urls: nil)
            }
            else{
                var urlImages: [String] = []
                let results = taskResult.result as? [AnyObject]
                for result in results!{
                    let urlResult = result.URLString
                    let string = urlResult!
                    if let range = string.rangeOfString("?") {
                        let firstPart = string[string.startIndex..<range.startIndex]
                        urlImages.append(firstPart)
                    }
                }
                completionHandler(error: false, urls: urlImages)
            }
            
            return nil
        })
    }
    
    
    class func createHTMLDocument(dictionary: NSDictionary) -> String {
        
        let file =  (dictionary.objectForKey("pathMessage") as! String).stringByAppendingString(".html")
        let metaFacebook =
            "<meta property=\"fb:app_id\" content=\"\(blicup_fb_id)\" />\n" +
            "<meta property=\"og:title\" content=\"\(dictionary.objectForKey("title")!)\" />\n" +
            "<meta property=\"og:type\" content=\"article\" />\n" +
            "<meta property=\"og:url\" content=\"\(AMAZON_S3_HTML_BASE)\(file) \" />\n" +
            "<meta property=\"og:image\" content=\"\(dictionary.objectForKey("image")!)\" />\n" +
            "<meta property=\"og:description\" content=\"\(dictionary.objectForKey("description")!)\" />\n" +
            "<meta property=\"al:ios:app_store_id\" content=\"\(blicup_appstore_id)\" />\n" +
            "<meta property=\"al:ios:url\" content=\"blicup://\(dictionary.objectForKey("pathMessage")!)\" />\n" +
            "<meta property=\"al:ios:app_name\" content=\"\(blicup_appstore_name)\" />\n" +
            "<meta property=\"al:web:should_fallback\" content=\"false\" />"
        
        
        
        let metaTwitter = "<meta name=\"twitter:card\" content=\"summary\" />\n" +
            "<meta name=\"twitter:site\" content=\"@blicup\" />\n" +
            "<meta name=\"twitter:title\" content=\"\(dictionary.objectForKey("title")!)\" />\n" +
            "<meta name=\"twitter:description\" content=\"\(dictionary.objectForKey("description")!)\" />\n" +
            "<meta name=\"twitter:image\" content=\"\(dictionary.objectForKey("image")!)\" />\n"
        
        let deeplink_js =
            "<script src=\"browser-deeplink.js\" type=\"text/javascript\"></script>\n" +
            "<script type=\"text/javascript\">\n" +
                "deeplink.setup({" +
                    "iOS: {" +
                        "appName: \"\(blicup_appstore_name)\"," +
                        "appId: \"\(blicup_appstore_id)\"," +
                    "}" +
                "});" +
        
            "window.onload = function() {" +
                "deeplink.open(\"blicup://\(dictionary.objectForKey("pathMessage")!) \");" +
            "}\n" +
            "</script>\n"
        
        let HTMLText = "<!DOCTYPE html>\n" +
            "<html lang=\"en-us\">\n" +
            "<head>\n" +
            "<meta charset=\"UTF-8\">\n" +
            "<title>Blicup</title>\n" +
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" +

            "\(deeplink_js)" +
            "\(metaFacebook)" +
            "\(metaTwitter)" +
            
            "</head>\n" +
            "<body>\n" +
            "</body>\n" +
        "</html>\n"
        return HTMLText
    }
    
    class func getChatAmazonUrl(whithChatId id: String) -> String {
        return AMAZON_S3_HTML_BASE + id + ".html"
    }
    
     
    class func registerAmazonSNSEndpointAfterLogin()
    {
        let sns = AWSSNS.defaultSNS()
        let request = AWSSNSCreatePlatformEndpointInput()
        request.token =    NSUserDefaults.standardUserDefaults().stringForKey("deviceToken")
        request.platformApplicationArn = SNSPlatformApplicationArn
        sns.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                print("Error: \(task.error)")
            } else {
                let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                print("endpointArn: \(createEndpointResponse.endpointArn)")
                NSUserDefaults.standardUserDefaults().setObject(createEndpointResponse.endpointArn, forKey: "endpointArn")
                
                UserBS.registerPushSNSEndpoint({ (success) in
                    print("Register succeded: \(success)")
                })
            }
            
            return nil
        })
    }
}


