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
        
        let color1 = UIColor.clearColor().CGColor
        let color2 = UIColor.blackColor().colorWithAlphaComponent(0.7).CGColor
        gradient.colors = [color1, color2]
        gradient.locations = [0.0, 1.0]
        
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
    
    func setMainColor(color:UIColor?) {
        guard let color = color else {
            return
        }
        
        let color1 = UIColor.clearColor().CGColor
        let color2 = color.darker().CGColor
        
        gradient.colors = [color1, color2]
    }

}
