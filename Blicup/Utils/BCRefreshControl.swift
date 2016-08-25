//
//  BCRefreshControl.swift
//  Blicup
//
//  Created by Guilherme Braga on 14/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BCRefreshControl: UIRefreshControl {

    private var customView = UIView()
    private var ivBlic = UIImageView()
    
    var isAnimating = false
    
    required override init() {
        
        super.init()
        
        self.backgroundColor = UIColor.clearColor()
        self.tintColor = UIColor.clearColor()
        
        customView = createCustomBlicupLoadingView()
        
        self.addSubview(customView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func beginRefreshing() {
        super.beginRefreshing()
        
        self.startBlicAnimation()
    }
    
    override func endRefreshing() {
        super.endRefreshing()
        
        self.ivBlic.stopAnimating()
        isAnimating = false
    }
    
    
    func startBlicAnimation() {
        isAnimating = true
        self.ivBlic.startAnimating()
    }
    
    // MARK: - Custom Blicup Loading View
    
    func createCustomBlicupLoadingView() -> UIView {
        
        let refreshContents = NSBundle.mainBundle().loadNibNamed("BCRefreshControlView", owner: self, options: nil)
        customView = refreshContents[0] as! UIView
        customView.frame = self.bounds
        
        
        ivBlic = customView.viewWithTag(999) as! UIImageView
        
        var animationArray: [UIImage] = []
        
        for index in 0...30 {
            animationArray.append(UIImage(named: "BlicUpdate_grey_\(index)")!)
        }
        
        ivBlic.animationImages = animationArray
        ivBlic.animationDuration = 1.0
        
        return customView
        
    }
    
}
