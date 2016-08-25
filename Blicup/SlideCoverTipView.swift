//
//  SlideCoverTipView.swift
//  Blicup
//
//  Created by Gustavo Tiago on 10/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit


@IBDesignable
class SlideCoverTipView: UIView {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var ivHand: UIImageView!
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.userInteractionEnabled = false
        nibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    private func nibSetup() {
        backgroundColor = .clearColor()
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        
        addSubview(view)
    }

    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: String(self.dynamicType), bundle: bundle)
        let nibView = nib.instantiateWithOwner(self, options: nil).first as! UIView
        
        return nibView
    }
    
    func startAnimation() {
        UIView.animateWithDuration(1, delay: 0.0, options: [UIViewAnimationOptions.CurveLinear], animations: {
            self.ivHand.transform = CGAffineTransformMakeTranslation(-40, 0)
        }) { (_) in
            UIView.animateWithDuration(0.5, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
                self.ivHand.transform = CGAffineTransformIdentity
                }, completion: { (_) in
                    self.startAnimation()
            })
        }
    }
    
    func stopAnimation() {
        NSUserDefaults.standardUserDefaults().setObject(["hasPerformedTip" : true], forKey: kSwipeCoverTipKey)
        UIView.animateWithDuration(0.5, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            self.view.alpha = 0.0
        }) { (_) in
            self.view.hidden = true
            self.removeFromSuperview()
        }
    }
    
}
