//
//  UserSearchCollectionViewCell.swift
//  Blicup
//
//  Created by Guilherme Braga on 21/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class UserSearchCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ivUserPhoto: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblBio: UILabel!
    
    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    let kVerifiedBadgeWidth: CGFloat = 15
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        ivUserPhoto.layer.cornerRadius = self.ivUserPhoto.frame.width/2
        ivUserPhoto.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivUserPhoto.image = nil
        lblUsername.text = nil
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
        self.layoutIfNeeded()
    }
}
