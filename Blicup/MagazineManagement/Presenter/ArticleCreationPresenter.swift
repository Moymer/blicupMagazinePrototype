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
    
    private var assets = [PHAsset]()
    private var titlesDic = [NSIndexPath:String]()
    private var contentsDic = [NSIndexPath:String]()
    
    
    override init() {
        super.init()
        options.deliveryMode = .Opportunistic
        options.synchronous = false
    }
    
    func setAssets(assets:[PHAsset]) {
        self.assets = assets
    }
    
    func addAssets(assets:[PHAsset]) {
        self.assets.appendContentsOf(assets)
    }
    
    func getAssetAtIndex(index: Int) -> PHAsset {
        return self.assets[index]
    }
    
    func addAssetsAtIndex(index: Int, element: PHAsset) {
        self.assets.insert(element, atIndex: index)
    }
    
    func deleteAsset(index: Int, completionHandler: (numberOfMedias: Int) -> ()) {
        self.assets.removeAtIndex(index)
        completionHandler(numberOfMedias: self.numberOfMedias())
    }
    
    func numberOfMedias()->Int {
        return assets.count
    }
    
    func setCardTexts(index: NSIndexPath, title:String?, content:String?) {
        titlesDic[index] = title
        contentsDic[index] = content
    }
    
    func getCardTitle(index:NSIndexPath)->String {
        guard let title = titlesDic[index] else {
            let placeholder = index.item == 0 ? "Story Title" : "Title"
            return placeholder
        }
        
        return title
    }
    
    func getCardContent(index:NSIndexPath)->String {
        guard let title = titlesDic[index] else {
            let placeholder = index.item == 0 ? "Location" : "Your text..."
            return placeholder
        }
        
        return title
    }
    
    func getImageMedia(index:NSIndexPath, completion:(image:UIImage?)->Void) {
        guard 0 <= index.item && index.item < assets.count else {
            completion(image: nil)
            return
        }
        
        let asset = assets[index.row]
        
        imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(300, 200), contentMode: PHImageContentMode.AspectFill, options: options) { (resultImage, info) in
            completion(image: resultImage)
        }
    }
}
