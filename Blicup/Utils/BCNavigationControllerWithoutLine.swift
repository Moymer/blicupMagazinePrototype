//
//  BCNavigationControllerWithoutLine.swift
//  Blicup
//
//  Created by Guilherme Braga on 07/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BCNavigationControllerWithoutLine: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.barTintColor = UIColor.whiteColor()
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Black", size: 18)!]
        hideNavBarSeparator()
    }
    
    func hideNavBarSeparator() {
        //this way transparent property continues working
        
        if let line = findShadowImageUnderView(navigationBar) {
            line.hidden = true
        }
        
    }
    
    private func findShadowImageUnderView(view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1 {
            return (view as! UIImageView)
        }
        
        for subview in view.subviews {
            if let imageView = findShadowImageUnderView(subview) {
                return imageView
            }
        }
        return nil
    }
}
