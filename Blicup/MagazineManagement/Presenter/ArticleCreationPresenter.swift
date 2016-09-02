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
    
    func deleteAsset(index: Int) {
        self.assets.removeAtIndex(index)
    }
    
    func numberOfMedias()->Int {
        return assets.count
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
