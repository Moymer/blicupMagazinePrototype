//
//  ChatRoomUserMentionCollectionViewCell.swift
//  Blicup
//
//  Created by Guilherme Braga on 31/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomUserMentionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ivUserPhoto: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        ivUserPhoto.layer.cornerRadius = self.ivUserPhoto.frame.width/2
        ivUserPhoto.layer.masksToBounds = true

    }
}
