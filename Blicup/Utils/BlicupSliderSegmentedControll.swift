//
//  BlicupSliderSegmentedControll.swift
//  Blicup
//
//  Created by Moymer on 29/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

@IBDesignable
class BlicupSliderSegmentedControll: UIView {
    
    @IBOutlet weak private var firstBtn: UIButton!
    @IBOutlet weak private var secondBtn: UIButton!
    @IBOutlet weak private var bottomBarWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    private func commonSetup() {
        let nib = UINib(nibName: "BlicupSliderSegmentedControll", bundle: NSBundle(forClass: self.dynamicType))
        let view = nib.instantiateWithOwner(self, options: nil).first as! UIView
        
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        self.addSubview(view)
    }
    
    @IBInspectable var firstText:String? = "First" {
        didSet {
            firstBtn.setTitle(firstText, forState: UIControlState.Normal)
        }
    }
    
    @IBInspectable var secondText:String? = "Second" {
        didSet {
            secondBtn.setTitle(secondText, forState: UIControlState.Normal)
        }
    }
    
    @IBInspectable var barWidth:CGFloat = 30.0 {
        didSet {
            bottomBarWidth.constant = barWidth
            self.layoutIfNeeded()
        }
    }
}
