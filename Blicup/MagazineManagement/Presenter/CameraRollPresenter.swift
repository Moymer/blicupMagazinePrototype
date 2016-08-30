//
//  CameraRollPresenter.swift
//  Blicup
//
//  Created by Moymer on 8/29/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos

class CameraRollPresenter: NSObject {

    var fetchResult: PHFetchResult?
    private let imageManager = PHCachingImageManager()
    private var thumbnailSize = CGSize(width: 120.0,height: 120.0)
    private var previousPreheatRect = CGRect.zero
    
 
    
    func loadAll( completionHandler:() -> Void )
    {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchResult = PHAsset.fetchAssetsWithOptions(allPhotosOptions)
        completionHandler()
    }
    
    func loadPhotos(  completionHandler:() -> Void )
    {
        let photosOptions = PHFetchOptions()
        photosOptions.predicate = NSPredicate(format:"mediaType = %d",PHAssetMediaType.Image.rawValue)
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchResult = PHAsset.fetchAssetsWithOptions( photosOptions)
        completionHandler()
        
    }
    
    func loadVideos(  completionHandler:() -> Void )
    {
        let photosOptions = PHFetchOptions()
        
        photosOptions.predicate = NSPredicate(format:"mediaType = %d",PHAssetMediaType.Video.rawValue)
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchResult = PHAsset.fetchAssetsWithOptions( photosOptions)
        completionHandler()
        
    }
    
    
    func countAssets() -> Int {
         return (fetchResult?.count)!
    }
    
    
    func getThumbImageFromAsset(indexPath : NSIndexPath, completionHandler: (image:Image, localIdentifier:String) -> Void ) {
        
        let asset = fetchResult?.objectAtIndex(indexPath.item) as! PHAsset
        imageManager.requestImageForAsset(asset, targetSize: thumbnailSize, contentMode:.AspectFill, options: nil, resultHandler: { image, _ in
            completionHandler(image: image!, localIdentifier: asset.localIdentifier )
        })

    }
    
    func getAssetIdentifier(indexPath:NSIndexPath) -> String
    {
         let asset = fetchResult?.objectAtIndex(indexPath.item) as! PHAsset
        return asset.localIdentifier
        
    }
}
