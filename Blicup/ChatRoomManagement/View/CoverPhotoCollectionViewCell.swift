//
//  CoverPhotoCollectionViewCell.swift
//  Blicup
//
//  Created by Moymer on 08/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CoverPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var btnRemoveCoverPhoto: UIButton!
    @IBOutlet weak var btnCoverPhoto: UIButton!
    
    override func awakeFromNib() {
        btnCoverPhoto.layer.cornerRadius = btnCoverPhoto.frame.width/2
        btnCoverPhoto.imageView?.contentMode = .ScaleAspectFill
        btnCoverPhoto.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        btnCoverPhoto.removeTarget(nil, action: nil, forControlEvents: .AllTouchEvents)
        btnRemoveCoverPhoto.removeTarget(nil, action: nil, forControlEvents: .AllTouchEvents)
    }
}
