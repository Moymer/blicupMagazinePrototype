//
//  CoverPhotoCollectionReusableView.swift
//  Blicup
//
//  Created by Guilherme Braga on 06/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CoverPhotoCollectionReusableView: UICollectionReusableView {
 
    @IBOutlet weak var btnAddCoverPhoto: UIButton!
    
    override func prepareForReuse() {
        btnAddCoverPhoto.removeTarget(nil, action: nil, forControlEvents: .AllTouchEvents)
        btnAddCoverPhoto.imageView?.image = nil
    }
}
