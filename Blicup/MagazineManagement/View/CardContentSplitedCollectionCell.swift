//
//  CardContentSplitedCollectionCell.swift
//  Blicup
//
//  Created by Moymer on 9/5/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos
class CardContentSplitedCollectionCell: UICollectionViewCell {


    
    
    @IBOutlet weak var ivPhoto: ScrollableImageView!
    @IBOutlet weak var lblCardTitle: UILabel!
    @IBOutlet weak var lblCardInfoText: UILabel!
    @IBOutlet weak var vVideo: FullscreenVideoView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    override func prepareForReuse() {
        ivPhoto.setImage(nil)
    }
    
    
    
    func setContentForPreview(card : [String:AnyObject], imageManager:PHCachingImageManager)
    {
        let asset : PHAsset = card["midia"] as! PHAsset
        let title : String = card["title"] as! String
        let infoText : String = card["infoText"] as! String
        
        lblCardTitle.text = title
        
        lblCardInfoText.text = infoText
        lblCardInfoText.sizeToFit()
        lblCardInfoText.layoutIfNeeded()
        
        if asset.mediaType == PHAssetMediaType.Image {
            vVideo.hidden = true
            ivPhoto.hidden = false
            ivPhoto.imageManager = imageManager
            ivPhoto.setPositioningScale(ScrollableImageViewPosAndScale.ASPECT_FILL)
            ivPhoto.setImageFromAsset(asset)
        } else {
            ivPhoto.hidden = true
            vVideo.hidden = false
            vVideo.imageManager = imageManager
            vVideo.phAsset = asset
        }
        
    }

}
