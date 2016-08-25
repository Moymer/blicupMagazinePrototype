//
//  TipsView.swift
//  Blicup
//
//  Created by Gustavo Tiago on 29/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

@objc protocol TipsViewProtocol: class {
    func tipViewClosePressed(sender: UIButton)
}

enum TipType: String {
    case PressChat = "PC"
    case GIFMessage = "GM"
    case MentionMessage = "MM"
}

@IBDesignable
class TipsView: UIView {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var lblTips: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    
    weak var delegate: TipsViewProtocol?
    var typeOfTip: TipType!
    var animatedTip = false
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    
    @IBAction func closePressed(sender: UIButton) {
        UIView.animateWithDuration(0.2, animations: {
            self.btnClose.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.delegate?.tipViewClosePressed(sender)
        }
        
    }
    
    func performedTaskTip() {
        delegate?.tipViewClosePressed(UIButton())
    }
    
}
