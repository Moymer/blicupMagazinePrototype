//
//  BlicCollectionViewCell.swift
//  Blicup
//
//  Created by Moymer on 26/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit


class BlicCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var ivBackground: UIImageView!
    @IBOutlet private weak var lblName: UILabel!
    @IBOutlet private weak var lblWhoCreatedUsername: UILabel!
    @IBOutlet private weak var ivVerifiedBadge: UIImageView!
    
    var backgroundImage: UIImage? {
        set {
            ivBackground.image = newValue
        }
        
        get {
            return ivBackground.image
        }
    }
    
    var creatorName: String? {
        set {
            self.lblWhoCreatedUsername.text = newValue
        }
        
        get {
            return self.lblWhoCreatedUsername.text
        }
    }
    
    var title: String? {
        set {
            self.lblName.text = newValue
        }
        
        get {
            return self.lblName.text
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
        ivBackground.image = nil
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        self.ivVerifiedBadge.hidden = !isVerified
        self.layoutIfNeeded()
    }
}
