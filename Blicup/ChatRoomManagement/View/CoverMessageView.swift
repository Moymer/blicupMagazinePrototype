//
//  CoverMessageView.swift
//  Blicup
//
//  Created by Moymer on 13/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CoverMessageView: UIView {

    @IBOutlet weak var ivPhoto: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblMessage: UILabel!

    class func newCoverMessage()->CoverMessageView {
        return NSBundle.mainBundle().loadNibNamed("CoverMessageView", owner: self, options: nil).first as! CoverMessageView
    }
}
