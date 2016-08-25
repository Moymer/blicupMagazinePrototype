//
//  BCGradientImageView.swift
//  Blicup
//
//  Created by Guilherme Braga on 14/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher
class BCGradientImageView: AnimatedImageView {

    private let gradient: CAGradientLayer = CAGradientLayer()
    
    override func awakeFromNib() {
        
        let color1 = UIColor.blackColor().colorWithAlphaComponent(0.7).CGColor as CGColorRef
        let color2 = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor as CGColorRef
        let color3 = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor as CGColorRef
        let color4 = UIColor.blackColor().colorWithAlphaComponent(0.7).CGColor as CGColorRef
        gradient.colors = [color1, color2, color3, color4]
        gradient.locations = [0.0, 0.25, 0.50, 1.0]
        
        self.layer.masksToBounds = true
        self.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        super.layoutSublayersOfLayer(layer)
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        gradient.frame = self.bounds
        CATransaction.commit()
    }

}
