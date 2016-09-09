//
//  CardContentOverCollectionCell.swift
//  Blicup
//
//  Created by Moymer on 8/31/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos
import Spring
class CardContentOverCollectionCell: UICollectionViewCell, ScrollableViewDelegate {
    
    private let bgAlpha : CGFloat = 0.7
    let dominantBrightness : CGFloat = 0.3
    var gl:CAGradientLayer?
 
    var repositioningDelegate : ArticlePreviewRepositioningDelegate?
    private var cardIdentifier : String?
    
    @IBOutlet weak var vMidia: ScrollableView!
    @IBOutlet weak var lblCardTitle: UILabel!
    @IBOutlet weak var lblCardInfoText: UILabel!
    @IBOutlet weak var vTextsContainer: SpringView!
    @IBOutlet weak var allTextView: UIView!
    
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
        lblCardTitle.text = nil
        lblCardInfoText.text = nil
        vTextsContainer.hidden = false
        stopAssets()
        stopRepositioning()
        
    }
    
    func stopAssets() {
        vMidia.setAsset(nil)
    }
    
    func setContentForPreview(card : [String:AnyObject], imageManager:PHCachingImageManager)
    {
        let asset : PHAsset = card["midia"] as! PHAsset
        let title : String = card["title"] as! String
        let infoText : String = card["infoText"] as! String
        
        lblCardTitle.text = title
        lblCardInfoText.text = infoText
        
        if  title == "" && infoText == "" {
            vTextsContainer.hidden = true
        } else {
            self.defaultTextAnimation()
        }
        
        cardIdentifier = asset.localIdentifier
        
        vMidia.hidden = false
        vMidia.imageManager = imageManager
        vMidia.zoomAndPosDelegate = self
        //change content midia positioning
        if let repositioning = repositioningDelegate?.getRepositioningFor(asset.localIdentifier)  {
            vMidia.setPositioningScale(ScrollableViewPosAndScale.BY_RECT, zoom: repositioning.0, offset: repositioning.1)
        } else {
            vMidia.setPositioningScale(ScrollableViewPosAndScale.ASPECT_FILL)
        }
        vMidia.setAsset(asset)
       
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
            gl?.removeFromSuperlayer()
            lblCardTitle.textColor = UIColor.whiteColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(bgAlpha)
            break
            
        case CardMode.OverCellDesign.Light.rawValue:
            gl?.removeFromSuperlayer()
            lblCardTitle.textColor = UIColor.blackColor()
            lblCardInfoText.textColor = lblCardTitle.textColor
            vTextsContainer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(bgAlpha)
            break
            
        case CardMode.OverCellDesign.Midia.rawValue:
            gl?.removeFromSuperlayer()
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
        gl = CAGradientLayer()
        gl?.frame = self.bounds
        gl!.startPoint = CGPoint(x: 0.5, y: 1.0)
        gl!.endPoint = CGPoint(x: 0.5, y: 0.0)
        gl!.colors = [ dominantColor.colorWithAlphaComponent(0.9).CGColor,dominantColor.colorWithAlphaComponent(0.5).CGColor,dominantColor.colorWithAlphaComponent(0.1).CGColor]
        gl!.locations = [ 0.0, 0.6, 1.0]
        gradientView.layer.addSublayer(gl!)
    }


    //MARK: - Repositioning
    
    func startRepositioning() {
        vMidia.scrollEnabled = true
        gradientView.hidden = true
        allTextView.hidden = true
    }
    
    func stopRepositioning() {
        vMidia.scrollEnabled = false
        gradientView.hidden = false
        allTextView.hidden = false
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if vMidia.scrollEnabled {
            return vMidia
        }
        return super.hitTest(point, withEvent: event)
    }
    
    //scalableView delegate
    func changeViewScalingOrPositioning( zoom:CGFloat, offset :CGPoint) -> Void {
        
        repositioningDelegate?.addImageRepositioning(cardIdentifier!, zoom: zoom, offset: offset)
    }
 
    
    //MARK: - Animation 
    
    func defaultTextAnimation() {
        vTextsContainer.animation = "squeezeUp"
        vTextsContainer.force = 0.7
        vTextsContainer.delay = 0.1
        vTextsContainer.duration = 0.7
        vTextsContainer.animate()
        

    }
}
