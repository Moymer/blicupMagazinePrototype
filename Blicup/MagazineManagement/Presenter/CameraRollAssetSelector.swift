//
//  CameraRollAssetSelector.swift
//  Blicup
//
//  Created by Moymer on 8/30/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos

class CameraRollAssetSelector: NSObject {

    let MAX_MIDIAS = 6
    let MAX_VIDEO_DURATION_SECS = 60.0
    var assetsSelected : [String:PHAsset] = [:]
    var assetsSelectedListOrdered : [String] = []
    
    
    func selectAsset(asset : PHAsset) {
        if assetsSelected[asset.localIdentifier]  == nil {
            assetsSelectedListOrdered.append(asset.localIdentifier)
            assetsSelected[asset.localIdentifier] = asset
        }
    }
    
    func unselectAsset(asset : PHAsset) {
        if assetsSelected[asset.localIdentifier]  != nil {
            assetsSelectedListOrdered.removeAtIndex(assetsSelectedListOrdered.indexOf(asset.localIdentifier)!)
            assetsSelected[asset.localIdentifier] = nil
        }
    }

    func getSelectionCount() -> Int {
        return assetsSelectedListOrdered.count
    }
    
    func hasReachedMidiaLimit() {
        assetsSelectedListOrdered.count == MAX_MIDIAS
    }
   
    
    func isAssetDurationOk(asset : PHAsset) -> Bool {
       return asset.duration <= MAX_VIDEO_DURATION_SECS
    }
    
    func isSelected(identifier:String) -> Int {
        if assetsSelected[identifier] != nil {
            return assetsSelectedListOrdered.indexOf(identifier)!
        } else {
            return -1
        }
    }
}
