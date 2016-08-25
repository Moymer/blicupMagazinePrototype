//
//  ShareChatView.swift
//  Blicup
//
//  Created by Gustavo Tiago on 09/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ShareChatViewProtocol: class {
    func sharePressed(sender: UIButton)
    func laterSharePressed(sender: UIButton)
}

@IBDesignable
class ShareChatView: UIView {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var lblShare: UILabel!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnLater: UIButton!
    @IBOutlet weak var vLayerLaterBtn: UIView!
    @IBOutlet weak var vLayerShareBtn: UIView!
    
    weak var delegate: ShareChatViewProtocol?
    
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
        
        self.btnLater.layer.cornerRadius = 18
        self.btnShare.layer.cornerRadius = 18
        self.vLayerLaterBtn.layer.cornerRadius = 18
        self.vLayerShareBtn.layer.cornerRadius = 18
        
        self.btnLater.clipsToBounds = true
        self.btnShare.clipsToBounds = true
        self.vLayerLaterBtn.clipsToBounds = true
        self.vLayerShareBtn.clipsToBounds = true
        
        self.btnLater.setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
        self.btnLater.setTitleColor(UIColor.blicupShareColor(), forState: .Highlighted)
        
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: String(self.dynamicType), bundle: bundle)
        let nibView = nib.instantiateWithOwner(self, options: nil).first as! UIView
        
        return nibView
    }
    
    @IBAction func btnSharePressed(sender: UIButton) {
        self.vLayerShareBtn.hidden = true
        delegate?.sharePressed(sender)
    }
    
    @IBAction func btnLaterPressed(sender: UIButton) {
        self.vLayerLaterBtn.hidden = true
        delegate?.laterSharePressed(sender)
    }
    
    //MARK: Buttons Actions
    @IBAction func dragExitShare(sender: AnyObject) {
        self.vLayerShareBtn.hidden = true
    }
    
    @IBAction func dragEnterShare(sender: AnyObject) {
        self.vLayerShareBtn.hidden = false
    }
    
    @IBAction func dragExitLater(sender: AnyObject) {
        self.vLayerLaterBtn.hidden = true
    }
    
    @IBAction func dragEnterLater(sender: AnyObject) {
        self.vLayerLaterBtn.hidden = false
    }
    
}
