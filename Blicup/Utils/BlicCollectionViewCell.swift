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
    
    var cornerRatius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        
        get {
            return self.layer.cornerRadius
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
            self.lblName.text = title
        }
        
        get {
            return self.lblName.text
        }
    }
    
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//    
//    private func commonInit() {
//        let view = NSBundle.mainBundle().loadNibNamed("CoverMessageView", owner: self, options: nil).first
//        self.addSubview(view)
//    }
    
    
    override func prepareForReuse() {
        ivBackground.image = nil
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        self.ivVerifiedBadge.hidden = !isVerified
        self.layoutIfNeeded()
    }
}
