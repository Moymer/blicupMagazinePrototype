//
//  ChatListToCoverTrasition.swift
//  Blicup
//
//  Created by Moymer on 01/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

protocol ChatListToCoverTrasitionProtocol: class {
    func snapshotViewToAnimateOnTrasition(chatIndex:NSIndexPath)->UIView
    func showSelectedChat(chatIndex:NSIndexPath)->CGRect
}


class ChatListToCoverNavDelegate: NSObject, UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
                
        if (fromVC is ChatListToCoverTrasitionProtocol && toVC is ChatRoomsListHorizontalPageViewController) ||
            (fromVC is ChatRoomsListHorizontalPageViewController && toVC is ChatListToCoverTrasitionProtocol) {
            
            let animator = ChatListToCoverTrasition()
            animator.presenting = (operation == .Push)
            return animator
        }
        
        return nil
    }
}


class ChatListToCoverTrasition: NSObject, UIViewControllerAnimatedTransitioning {
    private let animationDuration = 0.4
    var presenting = true
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return animationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView(),
            let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
                return
        }
        
        let toView = toViewController.view
        let fromView = fromViewController.view
        
        if presenting {
            guard let fromVCProtocol = fromViewController as? ChatListToCoverTrasitionProtocol,
                let coverVC = toViewController as? ChatRoomsListHorizontalPageViewController else {
                return
            }
            
            toView.hidden = true
            containerView.addSubview(toView)
            
            let transitionBckgrnd = UIView(frame: containerView.bounds)
            transitionBckgrnd.backgroundColor = UIColor.blackColor()
            transitionBckgrnd.alpha = 0.0
            containerView.addSubview(transitionBckgrnd)
            
            let index = coverVC.coverShowingIndex()
            let snapShot = fromVCProtocol.snapshotViewToAnimateOnTrasition(index)
            snapShot.frame = containerView.convertRect(snapShot.frame, fromView: fromView)
            containerView.addSubview(snapShot)
            
            let scaleFactor:CGFloat = toView.bounds.width/snapShot.bounds.width
            let scaleOrigin = CGPointMake(-snapShot.frame.origin.x * scaleFactor, -snapShot.frame.origin.y * scaleFactor)
            
            UIView.animateWithDuration(animationDuration, animations: {
                snapShot.frame = CGRectMake(0, 0, toView.bounds.width, toView.bounds.height)
                transitionBckgrnd.alpha = 1.0
                
                fromView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor)
                fromView.frame.origin = scaleOrigin
                
                }, completion: { (_) in
                    toView.hidden = false
                    snapShot.removeFromSuperview()
                    transitionBckgrnd.removeFromSuperview()
                    fromView.transform = CGAffineTransformIdentity
                    transitionContext.completeTransition(true)
            })
        }
        else {
            guard let toVCProtocol = toViewController as? ChatListToCoverTrasitionProtocol,
                let coverVC = fromViewController as? ChatRoomsListHorizontalPageViewController else {
                return
            }
            
            containerView.addSubview(toView)
            
            let index = coverVC.coverShowingIndex()
            let finalFrame = toVCProtocol.showSelectedChat(index)
            
            let transitionBckgrnd = UIView(frame: containerView.bounds)
            transitionBckgrnd.backgroundColor = UIColor.blackColor()
            transitionBckgrnd.alpha = 0.0
            containerView.addSubview(transitionBckgrnd)
            
            let snapShot = toVCProtocol.snapshotViewToAnimateOnTrasition(index)
            snapShot.frame = coverVC.view.bounds
            containerView.addSubview(snapShot)
            containerView.layoutSubviews()
            
            fromView.hidden = true
            
            let scaleFactor: CGFloat = snapShot.bounds.width/finalFrame.width
            let scaleOrigin = CGPointMake(-finalFrame.origin.x * scaleFactor, -finalFrame.origin.y * scaleFactor)
            
            toView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor)
            toView.frame.origin = scaleOrigin
            
            UIView.animateWithDuration(animationDuration, animations: {
                snapShot.frame = finalFrame
                transitionBckgrnd.alpha = 0.0
                toView.transform = CGAffineTransformIdentity
                toView.frame = containerView.bounds
                
                }, completion: { (_) in
                    snapShot.removeFromSuperview()
                    transitionBckgrnd.removeFromSuperview()
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(true)
            })
        }
    }
}
