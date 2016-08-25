//
//  AlphaVerticalSlideTransition.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class AlphaVerticalSlideTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let animationDuration = 0.4
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return animationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as UIViewController!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as UIViewController!
        let containerView = transitionContext.containerView()!
        
        let isPresenting = toViewController.presentedViewController != fromViewController
        let presentedController = isPresenting ? toViewController : fromViewController
        
        let background =  presentedController.view.viewWithTag(1)!
        let body = presentedController.view.viewWithTag(2)!
        
        if isPresenting {
            containerView.addSubview(presentedController.view)
            
            var startFrame = body.frame
            startFrame.origin.y = background.bounds.height
            let endFrame =  body.frame
            
            body.frame = startFrame
            background.alpha = 0
            
            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: [.CurveEaseOut], animations: {
                body.frame = endFrame
                background.alpha = 1
                
            }, completion:{ finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
            
        }
        else {
            //anima com frame
            var endFrame = body.frame
            endFrame.origin.y = background.bounds.height
            background.alpha = 1
            
            UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: {
                body.frame = endFrame
                background.alpha = 0
                
                }, completion:{ finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                    if !transitionContext.transitionWasCancelled() { toViewController.becomeFirstResponder() }
            })
        }
    }
}
