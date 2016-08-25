//
//  BlicupClock.swift
//  Blicup
//
//  Created by Moymer on 6/10/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BlicupClock: UIView {
    
    let defaultPercent : CGFloat = 0.02
    @IBInspectable var clockColor: UIColor = UIColor.whiteColor()
    
    let defaultSize : CGFloat = 20
    var currentState: CGFloat?
    
    // Creates a CGPath in the shape of a pie with slices missing
    private func clockCircle(rect: CGRect, percent:CGFloat) -> CGPath {
        
        let radius:CGFloat = min(rect.size.width/2,rect.size.height/2)
        let start:CGFloat =  CGFloat(-M_PI/2)
        let end = CGFloat(M_PI*2) * percent + CGFloat(-M_PI/2)
        let center = CGPoint(x: rect.size.width/2, y: rect.size.height/2)
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(center)
        bezierPath.addArcWithCenter(center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        bezierPath.addLineToPoint(center)
        return bezierPath.CGPath
    }
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        currentState = defaultPercent

        self.clipsToBounds = true
        self.layer.cornerRadius = min(self.bounds.size.width/2, self.bounds.size.height/2)

    }
    
    func updateBasedOnTime(time : Double)
    {
        let hoursSinceTime = min(23,max((NSDate().timeIntervalSince1970 - time ) / 3600.0, 0.5))
        currentState = CGFloat(hoursSinceTime/24.0)
  
        setNeedsDisplay()
    }

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {

        let ctx = UIGraphicsGetCurrentContext()
        CGContextAddPath(ctx, clockCircle(rect, percent: currentState!))
        let cgcolor = clockColor.CGColor
        CGContextSetFillColorWithColor(ctx,cgcolor)
        CGContextFillPath(ctx)

    }


}
