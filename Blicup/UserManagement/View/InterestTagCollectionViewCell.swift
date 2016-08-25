//
//  InterestTagCollectionViewCell.swift
//  Blicup
//
//  Created by Guilherme Braga on 17/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class InterestTagCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ivTag: UIImageView!
    @IBOutlet weak var lblTagName: UILabel!
    
    override func awakeFromNib() {
        
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
    }
    
    
    
}
