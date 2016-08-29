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
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            ivThumb.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivThumb.image = nil
    }
}
