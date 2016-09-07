//
//  PublishBlicCategoryCollectionViewCell.swift
//  Blicup
//
//  Created by Guilherme Braga on 06/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class PublishBlicCategoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ivMagazineCategory: BCGradientImageView!
    @IBOutlet weak var lblMagazineCategoryTitle: UILabel!
    
    //selection
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var ivSelectionCheck: UIImageView!
    @IBOutlet weak var lblSelectionCategory: UILabel!
 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        selectionView.hidden = true
    }
    
    func setSelectionAnimated() {
        
        if selected {
            selectionView.hidden = false
            selectionView.alpha = 0.0
            UIView.animateWithDuration(0.2, animations: {
                self.selectionView.alpha = 1.0
                self.lblMagazineCategoryTitle.alpha = 0
                self.ivSelectionCheck.transform = CGAffineTransformMakeScale(1.1, 1.1)
                
                }, completion: { (finish) in
                    self.lblMagazineCategoryTitle.hidden = true
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
            self.lblMagazineCategoryTitle.hidden = false
            
            UIView.animateWithDuration(0.25, animations: {
                self.selectionView.alpha = 0.0
                self.lblMagazineCategoryTitle.alpha = 1
                }, completion: { (finish) in
                    self.selectionView.alpha = 1.0
                    self.selectionView.hidden = true
            })
        }
    }
}
