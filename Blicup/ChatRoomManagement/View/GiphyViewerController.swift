//
//  GiphyViewerController.swift
//  Blicup
//
//  Created by Moymer on 06/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher

class GiphyViewerPresentingTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView(),
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
                return
        }
        
        let giphyController = toVC as! GiphyViewerController
        let initialFrame = giphyController.initialFrame
        let finalFrame = transitionContext.finalFrameForViewController(toVC)
        
        giphyController.ivGiphy.frame = initialFrame
        giphyController.ivGiphy.layer.cornerRadius = 4
        toVC.view.backgroundColor = UIColor.clearColor()
        
        let containerGiphy = UIView(frame: initialFrame)
        containerGiphy.backgroundColor = UIColor.lightGrayColor()
        containerGiphy.layer.cornerRadius = 4
        
        containerView.addSubview(containerGiphy)
        containerView.addSubview(toVC.view)
        
        let duration = transitionDuration(transitionContext)
        
        UIView.animateWithDuration(duration, animations: {
            giphyController.ivGiphy.frame = finalFrame
            giphyController.ivGiphy.layer.cornerRadius = 0
            toVC.view.backgroundColor = UIColor.blackColor()
        }) { (finished) in
            containerGiphy.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
}


class GiphyViewerDismissingTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let containerView = transitionContext.containerView() else {
                return
        }
        
        let giphyController = fromVC as! GiphyViewerController
        let finalFrame = giphyController.initialFrame
        
        let duration = transitionDuration(transitionContext)
        
        let containerGiphy = UIView(frame: finalFrame)
        containerGiphy.backgroundColor = UIColor.lightGrayColor()
        containerGiphy.layer.cornerRadius = 4
        containerView.insertSubview(containerGiphy, belowSubview: fromVC.view)
        
        UIView.animateWithDuration(duration, animations: {
            giphyController.ivGiphy.frame = finalFrame
            giphyController.ivGiphy.layer.cornerRadius = 4
            fromVC.view.backgroundColor = UIColor.clearColor()
        }) { (finished) in
            containerGiphy.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            if transitionContext.transitionWasCancelled() == false { toVC.becomeFirstResponder() }
        }
    }
}


class GiphyViewerInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    
    func wireToViewController(viewController: UIViewController!) {
        self.viewController = viewController
        prepareGestureRecognizerInView(viewController.view)
    }
    
    private func prepareGestureRecognizerInView(view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translationInView(gestureRecognizer.view!.superview!)
        var progress = sqrt(pow(translation.x, 2) + pow(translation.y, 2))/300
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            break
            
        case .Changed:
            shouldCompleteTransition = progress > 0.5
            updateInteractiveTransition(progress)
            break
            
        case .Cancelled:
            interactionInProgress = false
            cancelInteractiveTransition()
            break
            
        case .Ended:
            interactionInProgress = false
            
            if !shouldCompleteTransition {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
            }
            break
            
        default:
            print("Unsupported")
        }
    }
}



class GiphyViewerController: UIViewController, UIViewControllerTransitioningDelegate {
    private let swipeInteractionTransition = GiphyViewerInteractiveTransition()
    private let dismissAnimationTransition = GiphyViewerDismissingTransition()
    
    private var initialFrame:CGRect!
    private var giphyUrl:NSURL!
    @IBOutlet private weak var ivGiphy: AnimatedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ivGiphy.kf_setImageWithURL(giphyUrl)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(taped(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func taped(sender:UITapGestureRecognizer) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return GiphyViewerPresentingTransition()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimationTransition
    }
    
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return swipeInteractionTransition.interactionInProgress ? swipeInteractionTransition : nil
    }
    
    func loadGiphy(giphy:NSURL, withInitialFrame frame:CGRect) {
        self.initialFrame = frame
        self.giphyUrl = giphy
        swipeInteractionTransition.wireToViewController(self)
    }
    
    
    @IBAction func dismissPressed(sender: UIButton) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
