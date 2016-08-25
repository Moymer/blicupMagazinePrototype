//
//  WebImageSearchCollectionFooterReusableView.swift
//  Blicup
//
//  Created by Guilherme Braga on 28/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class WebImageSearchCollectionFooterReusableView: UICollectionReusableView {
        
    @IBOutlet weak var btnLoadMore: UIButton!
    @IBOutlet weak var aivLoading: UIActivityIndicatorView!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        btnLoadMore.hidden = true
        aivLoading.hidden = true
        
        btnLoadMore.setTitle(NSLocalizedString("Load More", comment: "Load More"), forState: .Normal)
        
    }
    
}
