//
//  CollectionViewTransition.swift
//  Blicup
//
//  Created by Guilherme Braga on 30/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

let animationDuration = 0.35
//TO DO: Pegar dados de gridwidth e scale do delegate
let GRID_WIDTH : CGFloat = (screenSize.width/2)-15.0 // 15 = 10 que é o tamanho do inset lateral + 5 (metade do inset entre as fotos)
let animationScale = screenWidth/GRID_WIDTH // screenWidth / the width of waterfall collection view's grid

class CollectionViewTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var presenting = false

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return animationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as UIViewController!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as UIViewController!
        let containerView = transitionContext.containerView()!
        
        if presenting {
            let toView = toViewController.view!
            containerView.addSubview(toView)
            toView.hidden = true
            
            let waterFallView = (toViewController as! CollectionViewTransitionProtocol).transitionCollectionView()
            let pageView = (fromViewController as! CollectionViewTransitionProtocol).transitionCollectionView()
            waterFallView.layoutIfNeeded()
            let indexPath = pageView.fromPageIndexPath()
            let gridView = waterFallView.cellForItemAtIndexPath(indexPath)
            let leftUpperPoint = gridView!.convertPoint(CGPointZero, toView: toViewController.view)
            
            let snapShot = (gridView as! CollectionTansitionWaterfallGridViewProtocol).snapShotForTransition()
            snapShot.transform = CGAffineTransformMakeScale(animationScale, animationScale)
            let pullOffsetY = (fromViewController as! CollectionHorizontalPageViewControllerProtocol).pageViewCellScrollViewContentOffset().y
            let offsetY : CGFloat = fromViewController.navigationController!.navigationBarHidden ? 0.0 : navigationHeaderAndStatusbarHeight
            snapShot.origin(CGPointMake(0, -pullOffsetY+offsetY))
            containerView.addSubview(snapShot)
            
            toView.hidden = false
            toView.alpha = 0
            toView.transform = snapShot.transform
            toView.frame = CGRectMake(-(leftUpperPoint.x * animationScale),-((leftUpperPoint.y-offsetY) * animationScale+pullOffsetY+offsetY),
                toView.frame.size.width, toView.frame.size.height)
            let whiteViewContainer = UIView(frame: screenBounds)
            whiteViewContainer.backgroundColor = UIColor.whiteColor()
            containerView.addSubview(snapShot)
            containerView.insertSubview(whiteViewContainer, belowSubview: toView)
            
            UIView.animateWithDuration(animationDuration, animations: {
                snapShot.transform = CGAffineTransformIdentity
                snapShot.frame = CGRectMake(leftUpperPoint.x, leftUpperPoint.y, snapShot.frame.size.width, snapShot.frame.size.height)
                toView.transform = CGAffineTransformIdentity
                toView.frame = CGRectMake(0, 0, toView.frame.size.width, toView.frame.size.height);
                toView.alpha = 1
                }, completion:{finished in
                    if finished {
                        snapShot.removeFromSuperview()
                        whiteViewContainer.removeFromSuperview()
                        transitionContext.completeTransition(true)
                    }
            })
        }else{
            let fromView = fromViewController.view
            let toView = toViewController.view
            
            let waterFallView : UICollectionView = (fromViewController as! CollectionViewTransitionProtocol).transitionCollectionView()
            let pageView : UICollectionView = (toViewController as! CollectionViewTransitionProtocol).transitionCollectionView()
            
            toView.hidden = true
            containerView.addSubview(toView)
            
            let indexPath = waterFallView.toIndexPath()
            let gridView = waterFallView.cellForItemAtIndexPath(indexPath)
            
            let leftUpperPoint = gridView!.convertPoint(CGPointZero, toView: nil)
            pageView.hidden = true
            pageView.scrollToItemAtIndexPath(indexPath, atScrollPosition:.CenteredHorizontally, animated: false)
            
            let offsetStatuBar : CGFloat = fromViewController.navigationController!.navigationBarHidden ? 0.0 :
            statubarHeight;
            let snapShot = (gridView as! CollectionTansitionWaterfallGridViewProtocol).snapShotForTransition()
            containerView.addSubview(snapShot)
            snapShot.origin(leftUpperPoint)
            
            
            UIView.animateWithDuration(animationDuration, animations: {
                snapShot.transform = CGAffineTransformMakeScale(animationScale,
                    animationScale)
                snapShot.frame = CGRectMake(0, 0, toViewController.view.bounds.size.width, toViewController.view.bounds.size.height)
                
                fromView.alpha = 0
                fromView.transform = snapShot.transform
                fromView.frame = CGRectMake(-(leftUpperPoint.x)*animationScale,
                    -(leftUpperPoint.y-offsetStatuBar)*animationScale+offsetStatuBar,
                    fromView.frame.size.width,
                    fromView.frame.size.height)
                
                },completion:{finished in
                    toView.hidden = false
                    snapShot.removeFromSuperview()
                    pageView.hidden = false
                    fromView.transform = CGAffineTransformIdentity
                    transitionContext.completeTransition(true)
            })
        }
    }
}
