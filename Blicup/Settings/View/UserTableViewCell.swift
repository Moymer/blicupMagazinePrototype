//
//  UserTableViewCell.swift
//  Blicup
//
//  Created by Guilherme Braga on 15/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

@objc protocol UserTableViewCellProtocol: class {
    func userTableViewCellFollowPressed(cell: UserTableViewCell)
    optional func userTableViewCellUnblockPressed(cell: UserTableViewCell)
}


@IBDesignable
class UserTableViewCell: UITableViewCell {
    
    enum CellState {
        case None, UnFollow, Block
    }
    
    @IBOutlet weak var ivUserPhoto: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var btnFollow: UIButton!
    @IBOutlet weak var btnBlock: UIButton!
    
    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    let kVerifiedBadgeWidth: CGFloat = 15
    
    @IBOutlet weak var constrBtnFollowWidth: NSLayoutConstraint!
    var kDefaultWidth: CGFloat = 90
    

    weak var delegate: UserTableViewCellProtocol?
    
    var state = CellState.UnFollow {
        didSet {
            self.confiCellBtns()
        }
    }

        
    override func awakeFromNib() {
        super.awakeFromNib()
        ivUserPhoto.layer.cornerRadius = self.ivUserPhoto.frame.width/2
        lblUsername.text = nil
        
        btnFollow.layer.cornerRadius = btnFollow.bounds.height/2
        let followingImage = UIImage(color: UIColor.blicupPink())
        btnFollow.setBackgroundImage(followingImage, forState: UIControlState.Selected)
        btnFollow.layer.borderWidth = 2.0
        
        btnBlock.layer.cornerRadius = btnBlock.bounds.height/2
        calculateBtnFollowWidth()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        btnFollow.hidden = false
        ivUserPhoto.image = nil
        lblUsername.text = nil
        btnFollow.hidden = false
        btnBlock.hidden = true
    }
    
    // MARK: - Button Follow Configuration
    private func confiCellBtns() {
        btnFollow.hidden = (state != .UnFollow)
        btnBlock.hidden = (state != .Block)
        constrBtnFollowWidth.constant = state == .None ? 0 : kDefaultWidth
    }
    
    func setFollowing(following:Bool) {
        btnFollow.selected = following
        btnFollow.layer.borderColor = following ? UIColor.blicupPink().CGColor : UIColor.blicupGray2().CGColor
    }
    
    func calculateBtnFollowWidth() {
        
        guard let font = self.btnFollow.titleLabel?.font else {
            return
        }
        
        let title = NSLocalizedString("Following", comment: "Following")
        
        let constraintRect = CGSize(width: CGFloat.max, height: self.btnFollow.frame.height)
        let boundingBtn = title.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        kDefaultWidth = boundingBtn.width + 25
        constrBtnFollowWidth.constant = kDefaultWidth
        self.btnFollow.layoutIfNeeded()
        
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
        self.layoutIfNeeded()
    }

    
    // MARK: - Actions
    @IBAction func btnBlockPressed(sender: UIButton) {
        self.delegate?.userTableViewCellUnblockPressed?(self)
    }
    
    @IBAction func btnFollowPressed(sender: AnyObject) {
        self.delegate?.userTableViewCellFollowPressed(self)
    }
}
