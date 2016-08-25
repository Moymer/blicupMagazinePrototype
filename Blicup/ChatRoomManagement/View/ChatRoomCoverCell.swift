//
//  ChatRoomCoverCell.swift
//  Blicup
//
//  Created by Moymer on 25/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher

class ChatRoomCoverCell: UICollectionViewCell {
    
    @IBOutlet weak var tvPhotos: UITableView!
    
    var cellIndex = 0 {
        didSet {
            tvPhotos.tag = cellIndex
            tvPhotos.reloadData()
            tvPhotos.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        }
    }
}


class ChatRoomCoverPhotoCell: UITableViewCell {
    let aivBackgroundPhoto = AnimatedImageView()
    
    required convenience init(reuseIdentifier identifier:String) {
        self.init(style: UITableViewCellStyle.Default, reuseIdentifier: identifier)
        aivBackgroundPhoto.backgroundColor = UIColor.clearColor()
        aivBackgroundPhoto.needsPrescaling = false
        aivBackgroundPhoto.autoPlayAnimatedImage = true
        aivBackgroundPhoto.framePreloadCount = 2
        aivBackgroundPhoto.contentMode = UIViewContentMode.ScaleAspectFill
        aivBackgroundPhoto.clipsToBounds = true
        self.backgroundView = aivBackgroundPhoto
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        aivBackgroundPhoto.kf_cancelDownloadTask()
        aivBackgroundPhoto.image = nil
    }
}
