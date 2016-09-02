//
//  CameraRollAssetSelector.swift
//  Blicup
//
//  Created by Moymer on 8/30/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos


public protocol CameraRollAssetSelectionDelegate : NSObjectProtocol {
    
    func selectedAssets(numberSelected: Int)
}

class CameraRollAssetSelector: NSObject {

    var MAX_MIDIAS = 6
    let MAX_VIDEO_DURATION_SECS = 61.0
    var assetsSelected : [String:PHAsset] = [:]
    var assetsSelectedListOrdered : [String] = []
    
    var delegate:CameraRollAssetSelectionDelegate?
    
    func selectAsset(asset : PHAsset) {
        if assetsSelected[asset.localIdentifier]  == nil {
            assetsSelectedListOrdered.append(asset.localIdentifier)
            assetsSelected[asset.localIdentifier] = asset
            
            delegate?.selectedAssets(assetsSelectedListOrdered.count)
        }
    }
    
    func unselectAsset(asset : PHAsset) {
        if assetsSelected[asset.localIdentifier]  != nil {
            assetsSelectedListOrdered.removeAtIndex(assetsSelectedListOrdered.indexOf(asset.localIdentifier)!)
            assetsSelected[asset.localIdentifier] = nil
            
            delegate?.selectedAssets(assetsSelectedListOrdered.count)
        }
    }

    func getSelectionCount() -> Int {
        if MAX_MIDIAS != 6 {
            return (6 - MAX_MIDIAS) + assetsSelectedListOrdered.count
        }
        return assetsSelectedListOrdered.count
    }
    
    func hasReachedMidiaLimit() -> Bool {
        return assetsSelectedListOrdered.count == MAX_MIDIAS
    }
   
    
    func isAssetDurationOk(asset : PHAsset) -> Bool {
       return asset.duration < MAX_VIDEO_DURATION_SECS
    }
    
    func isSelected(identifier:String) -> Int {
        if assetsSelected[identifier] != nil {
            return assetsSelectedListOrdered.indexOf(identifier)!
        } else {
            return -1
        }
    }
    
    func getSelectedAssetsOrdered() -> [PHAsset] {
        var orderedAssets:[PHAsset]  = []
        for identifier in assetsSelectedListOrdered {
            orderedAssets.append(assetsSelected[identifier]!)
        }
        return orderedAssets
    }
}
