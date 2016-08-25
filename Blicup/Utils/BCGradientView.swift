//
//  BCGradientView.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BCGradientView: UIView {

    private let gradient: CAGradientLayer = CAGradientLayer()

    lazy var aiView: UIActivityIndicatorView = {
        let aiView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        aiView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        aiView.center = self.center
        aiView.hidesWhenStopped = true
        return aiView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customizeView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func customizeView() {
        
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
        
        let color1 = UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor as CGColorRef
        let color2 = UIColor.clearColor().CGColor as CGColorRef
        let color3 = UIColor.clearColor().CGColor as CGColorRef
        let color4 = UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor as CGColorRef
        gradient.colors = [color1, color2, color3, color4]
        gradient.locations = [0.0, 0.25, 0.75, 1.0]
        
        self.layer.masksToBounds = true
        self.layer.insertSublayer(gradient, atIndex: 0)
        
        self.addSubview(aiView)
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        super.layoutSublayersOfLayer(layer)
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        gradient.frame = self.bounds
        CATransaction.commit()
    }
}
