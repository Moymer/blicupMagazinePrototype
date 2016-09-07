//
//  CardContentSplitedCollectionCell.swift
//  Blicup
//
//  Created by Moymer on 9/5/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos

class CardContentSplitedCollectionCell: CardContentOverCollectionCell {
    
    let contentDark : UIColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    
    override func setContentForPreview(card : [String:AnyObject], imageManager:PHCachingImageManager, design: Int)
    {
        
        setContentForPreview(card, imageManager: imageManager)
        
        switch design {
        case CardMode.SplitCellDesign.Dark.rawValue:
            lblCardTitle.textColor = UIColor.whiteColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = contentDark
            break
            
        case CardMode.SplitCellDesign.Light.rawValue:
            lblCardTitle.textColor = UIColor.blackColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.whiteColor()
            break
            
        case CardMode.SplitCellDesign.Midia.rawValue:
            let dominantColor = card["midiaDominantColor"] as! UIColor
            var hue         : CGFloat = 0
            var saturation  : CGFloat = 0
            var brightness  : CGFloat = 0
            var alpha       : CGFloat = 0
            
            if dominantColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                lblCardTitle.textColor =   UIColor.whiteColor()
                lblCardInfoText.textColor = lblCardTitle.textColor
                vTextsContainer.backgroundColor =  UIColor( hue: hue, saturation: saturation, brightness: dominantBrightness, alpha: alpha)
            }
            break
            
            
        default:
            lblCardTitle.textColor = UIColor.whiteColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = contentDark
            
        }
    }
}
