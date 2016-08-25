//
//  BCProgress.swift
//  Blicup
//
//  Created by Guilherme Braga on 24/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BCProgress: UIView {
    
    var background: UIImageView = UIImageView()
    var loadingView: UIView = UIView()
    var progressBlicupLogo: UIImageView = UIImageView()
    
    
    /*
     Show customized activity indicator,
     actually add activity indicator to passing view
     
     @param view - add activity indicator to this view
     */
    func showHUDAddedTo(view: UIView) {
        
        background.frame = view.frame
        background.center = view.center
        background.image = UIImage(named: "LogginInBlack")
        background.alpha = 0
        
        loadingView.frame = CGRectMake(0, 0, 80, 80)
        loadingView.center = view.center
        loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        progressBlicupLogo = self.createCustomBlicupLoadingView()
        progressBlicupLogo.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2)
        
        loadingView.transform = CGAffineTransformMakeScale(0.1, 0.1)
        
        loadingView.addSubview(progressBlicupLogo)
        background.addSubview(loadingView)
        view.addSubview(background)
        view.userInteractionEnabled = false
        progressBlicupLogo.startAnimating()
        
        
        UIView.animateWithDuration(0.7) { () -> Void in
            self.background.alpha = 1
            self.loadingView.transform = CGAffineTransformIdentity
        }
    }
    
    /*
     Hide activity indicator
     Actually remove activity indicator from its super view
     
     @param view - remove activity indicator from this view
     */
    
    func hideActivityIndicator(view: UIView) {
        progressBlicupLogo.stopAnimating()
        
        UIView.animateWithDuration(0.7, animations: { () -> Void in
            
            self.background.alpha = 0
            
            }, completion: { (finished) -> Void in
                self.background.removeFromSuperview()
                view.userInteractionEnabled = true
        })
    }
    
    
    
    // MARK: - Custom Blicup Loading View
    
    func createCustomBlicupLoadingView() -> UIImageView {
        
        let imageView = UIImageView.init(frame: CGRectMake(0.0, 0.0, 40.0, 40.0))
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_\(index)")!)
        }
        
        imageView.animationImages = animationArray
        imageView.animationDuration = 1.0
        
        return imageView
        
    }
    
}
