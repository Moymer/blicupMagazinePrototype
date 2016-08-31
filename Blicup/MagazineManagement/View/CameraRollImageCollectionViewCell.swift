//
//  CameraRollImageCollectionViewCell.swift
//  Blicup
//
//  Created by Moymer on 8/29/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CameraRollImageCollectionViewCell: UICollectionViewCell {
 
    @IBOutlet weak var ivThumb: UIImageView!
    
    //selection
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var ivSelectionCheck: UIImageView!
    @IBOutlet weak var lblSelectionOrder: UILabel!
  
    //video
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var icVideoIndicator: UIImageView!
    @IBOutlet weak var lblVideoDuration: UILabel!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            ivThumb.image = thumbnailImage
        }
    }
    
    override func awakeFromNib() {
        
        
        lblVideoDuration.layer.shadowOpacity = 0.35;
        lblVideoDuration.layer.shadowRadius = 2.0;
        lblVideoDuration.layer.shadowColor = UIColor.blackColor().CGColor;
        lblVideoDuration.layer.shadowOffset = CGSizeMake(0.0, 2.0);
        
        
        icVideoIndicator.layer.shadowOpacity = 0.35;
        icVideoIndicator.layer.shadowRadius = 2.0;
        icVideoIndicator.layer.shadowColor = UIColor.blackColor().CGColor;
        icVideoIndicator.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivThumb.image = nil
    }
    
    
    var duration: NSTimeInterval!{
        didSet {
            if duration == 0.0
            {
                videoView.hidden = true
            }
            else
            {
                videoView.hidden = false
                var secs = (Int) (duration % 60)
                let mins = (Int) (floor( duration / 60 ))
                if mins == 0 && secs == 0 {
                    secs = 1
                }
                lblVideoDuration.text = String(format: "%02d:%02d", mins, secs)

            }
        }
    }
    
    func checkSelection(assetSelector : CameraRollAssetSelector) -> Bool
    {
        var selected : Bool = false
        let pos = assetSelector.isSelected(representedAssetIdentifier)
        if  pos >= 0 {
            selectionView.hidden = false
            lblSelectionOrder.text = (pos == 0) ? "Cover" : "\(pos)"
            selected = true
        }
        else {
            selectionView.hidden = true
        }
        return selected
    }
    
    func setSelectionAnimated(assetSelector : CameraRollAssetSelector)
    {
        let selected = checkSelection(assetSelector)
        if  selected {
            selectionView.alpha = 0.0
            UIView.animateWithDuration(0.2, animations: {
                self.selectionView.alpha = 1.0
                self.ivSelectionCheck.transform = CGAffineTransformMakeScale(1.1, 1.1)

                }, completion: { (finish) in
                    
                    UIView.animateWithDuration(0.1, animations: {
                        self.ivSelectionCheck.transform = CGAffineTransformMakeScale(1.25, 1.25)

                        }, completion: { (finish) in
                            UIView.animateWithDuration(0.1, animations: {
                                self.ivSelectionCheck.transform = CGAffineTransformMakeScale(0.8, 0.8)

                                }, completion: { (finish) in
                                    
                                    UIView.animateWithDuration(0.1, animations: {
                                        self.ivSelectionCheck.transform = CGAffineTransformIdentity

                                    })
                                    
                            })
                    })
                    
            })
        } else {
            self.selectionView.hidden = false
            self.selectionView.alpha = 1.0
            
            UIView.animateWithDuration(0.25, animations: {
                self.selectionView.alpha = 0.0
                
                }, completion: { (finish) in
                    self.selectionView.alpha = 1.0
                    self.selectionView.hidden = true
            })

        }
    }
}
