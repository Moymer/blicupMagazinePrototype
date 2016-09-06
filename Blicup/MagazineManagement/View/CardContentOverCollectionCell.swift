//
//  CardContentOverCollectionCell.swift
//  Blicup
//
//  Created by Moymer on 8/31/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos
class CardContentOverCollectionCell: UICollectionViewCell {

    private let bgAlpha : CGFloat = 0.7
    let dominantBrightness : CGFloat = 0.3
    var gl:CAGradientLayer?
    
    @IBOutlet weak var ivPhoto: ScrollableImageView!
    @IBOutlet weak var lblCardTitle: UILabel!
    @IBOutlet weak var lblCardInfoText: UILabel!
    @IBOutlet weak var vTextsContainer: UIView!
    @IBOutlet weak var vVideo: FullscreenVideoView!
    
    //just over variables
    @IBOutlet weak var infoTextLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoTextTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    

    override func prepareForReuse() {
        ivPhoto.setImage(nil)
    }
    
    func setTexts(title:String, infoText:String) {
        lblCardTitle.text = title
        
        lblCardInfoText.text = infoText
        lblCardInfoText.sizeToFit()
        lblCardInfoText.layoutIfNeeded()
      
        setMockImage()
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
    
    func setContentForPreview(card : [String:AnyObject], imageManager:PHCachingImageManager, design: Int)
    {
        
        setContentForPreview(card, imageManager: imageManager)
        
        infoTextLeadingConstraint.constant = 14
        infoTextTrailingConstraint.constant = 14
        titleLeadingConstraint.constant = 14
        titleTrailingConstraint.constant = 14
        
        
        switch design {
        case CardMode.OverCellDesign.Dark.rawValue:
            gradientView.hidden = true
            lblCardTitle.textColor = UIColor.whiteColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(bgAlpha)
            break
            
        case CardMode.OverCellDesign.Light.rawValue:
            gradientView.hidden = true
            lblCardTitle.textColor = UIColor.blackColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(bgAlpha)
            break
            
        case CardMode.OverCellDesign.Midia.rawValue:
            gradientView.hidden = true
            let dominantColor = card["midiaDominantColor"] as! UIColor
            var hue         : CGFloat = 0
            var saturation  : CGFloat = 0
            var brightness  : CGFloat = 0
            var alpha       : CGFloat = 0
            
            if dominantColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                lblCardTitle.textColor =   UIColor.whiteColor()
                lblCardInfoText.textColor = lblCardTitle.textColor
                vTextsContainer.backgroundColor =  UIColor( hue: hue, saturation: saturation, brightness: dominantBrightness, alpha: alpha).colorWithAlphaComponent(bgAlpha)
            }
            break
   
        case CardMode.OverCellDesign.MidiaGradient.rawValue:
          
            infoTextLeadingConstraint.constant = 0
            infoTextTrailingConstraint.constant = 0
            titleLeadingConstraint.constant = 0
            titleTrailingConstraint.constant = 0
            
            let dominantColor = card["midiaDominantColor"] as! UIColor
            var hue         : CGFloat = 0
            var saturation  : CGFloat = 0
            var brightness  : CGFloat = 0
            var alpha       : CGFloat = 0

            lblCardTitle.textColor = UIColor.whiteColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.clearColor()
            if dominantColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                addGradient( UIColor( hue: hue, saturation: saturation, brightness: 0.5, alpha: alpha))
            }

            break
            
            
        default:
            lblCardTitle.textColor = UIColor.whiteColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(bgAlpha)
        }
    }
    
    
    private func addGradient(dominantColor : UIColor) {
        gl?.removeFromSuperlayer()
        gradientView.hidden = false
        gl = CAGradientLayer()
        gl?.frame = self.bounds
        gl!.startPoint = CGPoint(x: 0.5, y: 1.0)
        gl!.endPoint = CGPoint(x: 0.5, y: 0.0)
        gl!.colors = [ dominantColor.colorWithAlphaComponent(0.9).CGColor,dominantColor.colorWithAlphaComponent(0.5).CGColor,dominantColor.colorWithAlphaComponent(0.1).CGColor]
        gl!.locations = [ 0.0, 0.6, 1.0]
        gradientView.layer.addSublayer(gl!)
    }
    
    private func setMockImage()
    {
       ivPhoto.setImageFromUrls(nil, photoUrl: NSURL(string: "http://www.cbc.ca/documentaries/content/images/blog/greatbarrierreef1_1920.jpg")!)
    }
    



    /**
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        return ivPhoto
    }
 **/
}
