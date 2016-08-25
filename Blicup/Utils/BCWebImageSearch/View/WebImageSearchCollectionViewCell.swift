//
//  WebImageSearchCollectionViewCell.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher

class WebImageSearchCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: AnimatedImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.contentMode = .ScaleAspectFill
        self.imageView.needsPrescaling = false
        self.imageView.autoPlayAnimatedImage = true
        self.imageView.framePreloadCount = 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}
