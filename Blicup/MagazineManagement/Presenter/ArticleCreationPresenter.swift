//
//  ArticleCreationPresenter.swift
//  Blicup
//
//  Created by Moymer on 31/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos

class ArticleCreationPresenter: NSObject {
    private let imageManager = PHCachingImageManager()
    private let options = PHImageRequestOptions()
    
    private let ASSET_KEY = "Asset", TITLE_KEY = "Title", CONTENT_KEY = "Content"
    var articleParts = [Dictionary<String,AnyObject>]()
    
    
    override init() {
        super.init()
        options.deliveryMode = .Opportunistic
        options.synchronous = false
    }
    
    func addAssets(assets:[PHAsset]) {
        for asset in assets {
            var dictionary = [String:AnyObject]()
            dictionary[ASSET_KEY] = asset
            articleParts.append(dictionary)
        }
    }
    
    func getAssetAtIndex(index: Int) -> PHAsset {
        return self.assets[index]
    }
    
    func addAssetsAtIndex(index: Int, element: PHAsset) {
        self.assets.insert(element, atIndex: index)
    }
    
    func deleteAsset(index: Int, completionHandler: (numberOfMedias: Int) -> ()) {
        self.articleParts.removeAtIndex(index)
        
        if index == 0, var coverDic = self.articleParts.first {
            coverDic[CONTENT_KEY] = nil
            articleParts[0] = coverDic
        }
        
        completionHandler(numberOfMedias: self.numberOfMedias())
    }
    
    func numberOfMedias()->Int {
        return articleParts.count
    }
    
    func setCardTexts(index: NSIndexPath, title:String?, content:String?) {
        var articleDic = self.articleParts[index.item]
        articleDic[TITLE_KEY] = title
        articleDic[CONTENT_KEY] = content
        self.articleParts[index.item] = articleDic
    }
    
    func getCardTitle(index:NSIndexPath)->String? {
        var articleDic = self.articleParts[index.item]
        return (articleDic[TITLE_KEY] as? String)
    }
    
    func getCardContent(index:NSIndexPath)->String? {
        var articleDic = self.articleParts[index.item]
        return (articleDic[CONTENT_KEY] as? String)
    }
    
    func getImageMedia(index:NSIndexPath, completion:(image:UIImage?)->Void) {
        guard 0 <= index.item && index.item < articleParts.count else {
            completion(image: nil)
            return
        }
        
        let part = articleParts[index.row]
        
        guard let asset = part[ASSET_KEY] as? PHAsset else {
            completion(image: nil)
            return
        }
        
        imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(300, 200), contentMode: PHImageContentMode.AspectFill, options: options) { (resultImage, info) in
            completion(image: resultImage)
        }
    }
}
