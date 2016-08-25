//
//  ChatRoomTalkInfoViewController.swift
//  Blicup
//
//  Created by Gustavo Tiago on 19/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomTalkInfoViewController: UserListFollowBlockViewController, UserProfileViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var vShadowContent: UIView!
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var lblNumberOfParticipants: UILabel!
    
    @IBOutlet weak var btnClose: BCCloseButton!
    private let talkPresenter = ChatRoomTalkInfoPresenter()
    
    var lblNoInternet: UILabel!
    var ivBlic = UIImageView()
    var originFrameView: CGPoint?
    var chatRoomID: String!
    var chatOwner: String?
    var finishedLoadingUserList = false
    let swipeInteractionTransition = TalkInfoInteractiveTransition()
    private let userProfileAnimationTransition = AlphaVerticalSlideTransition()
    
    private let kShowUserProfile = "showUserProfile"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = talkPresenter
        
        vContent.layer.cornerRadius = 10
        vContent.layer.masksToBounds = true
        lblNumberOfParticipants.alpha = 0
        
        self.createCustomBlicupLoadingView()
        self.ivBlic.startAnimating()
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            if !self.finishedLoadingUserList{
                self.ivBlic.alpha = 1
            }
        }
        
        createCustomLblNoInternet()
        
        self.originFrameView = self.vContent.center
        
        swipeInteractionTransition.wireToViewController(self)
        
        talkPresenter.loadChatRoomUsers(chatRoomID) { (success) in
            self.finishedLoadingUserList = true
            if success {
                self.reloadDataInView()
            } else {
                self.showNoInternet()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        lblNumberOfParticipants.text = "\(presenter.userCount())"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenChatMembers()
    }
    
    // MARK: - Outlets Configuration
    
    func createCustomBlicupLoadingView() {
        ivBlic.contentMode = UIViewContentMode.ScaleAspectFit
        ivBlic.image = UIImage(named: "BlicUpdate_grey_0")
        
        var animationArray = [UIImage]()
        
        for index in 0...30 {
            animationArray.append(UIImage(named: "BlicUpdate_grey_\(index)")!)
        }
        
        ivBlic.animationImages = animationArray
        ivBlic.animationDuration = 1.0
        ivBlic.frame = CGRectMake(0, 0, 35, 35)
        ivBlic.center = CGPointMake(self.view.center.x - 15, self.view.center.y - 55)
        ivBlic.alpha = 0
        self.vContent.addSubview(ivBlic)
        
    }
    
    func createCustomLblNoInternet(){
        lblNoInternet = UILabel(frame: CGRectMake(0, 0, self.view.bounds.width, 20))
        lblNoInternet.textAlignment = .Center
        lblNoInternet.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        lblNoInternet.textColor = UIColor(colorLiteralRed: 120.0/255, green: 120.0/255, blue: 120.0/255, alpha: 1.0)
        lblNoInternet.center = CGPointMake(self.view.center.x - 15, self.view.center.y - 70)
        lblNoInternet.text = NSLocalizedString("No internet", comment: "")
        lblNoInternet.alpha = 0
        self.vContent.addSubview(lblNoInternet)
    }
    
    
    // MARK: - TableView Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !presenter.isBlockingMe(indexPath) && !presenter.isLoggedUser(indexPath) {
            let user = presenter.userAtIndex(indexPath)
            self.performSegueWithIdentifier(kShowUserProfile, sender: user)
        }
    }
    
    // MARK: - TableView Helper
    
    func reloadDataInView(){
        
        UIView.animateWithDuration(0.5, animations: {
            self.ivBlic.alpha = 0
            self.ivBlic.stopAnimating()
        }) { (_) in
            UIView.animateWithDuration(0.1, animations: {
                self.lblNumberOfParticipants.alpha = 1
                self.tableView.reloadData()
                self.lblNumberOfParticipants.text = "\(self.presenter.userCount())"
            })
        }
        
    }
    
    func showNoInternet(){
        UIView.animateWithDuration(0.2, animations: {
            self.ivBlic.alpha = 0
            self.ivBlic.stopAnimating()
        }) { (_) in
            UIView.animateWithDuration(0.4, animations: {
                self.lblNoInternet.alpha = 1
            })
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func closePressed(sender: AnyObject) {
        UIView.animateWithDuration(0.1, animations: {
            self.btnClose.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    
    // MARK : UserProfileViewControllerDelegate
    func presentUserProfileCardFromSelectedUser(user: User) {
        self.performSegueWithIdentifier(kShowUserProfile, sender: user)
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kShowUserProfile, let vcUserProfile = segue.destinationViewController as? UserProfileViewController {
            if let user = sender as? User {
                let presenter = UserProfileCardPresenter(user: user)
                vcUserProfile.presenter = presenter
                vcUserProfile.transitioningDelegate = vcUserProfile
                vcUserProfile.modalPresentationStyle = .Custom
                vcUserProfile.delegate = self
            }
        }
    }
    
    
    // MARK: Transition delegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return userProfileAnimationTransition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return userProfileAnimationTransition
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return swipeInteractionTransition.interactionInProgress ? swipeInteractionTransition : nil
    }
}

class TalkInfoInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    private var initialOffset: CGFloat = 0.0
    
    func wireToViewController(viewController: ChatRoomTalkInfoViewController!) {
        self.viewController = viewController
        initialOffset = viewController.vContent.frame.origin.y
        prepareGestureRecognizerInView(viewController.vContent)
    }
    
    private func prepareGestureRecognizerInView(view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translationInView(viewController.view)
        var progress:CGFloat = 0.0
        if translation.y > 0 {
            progress = (translation.y/(viewController.view.bounds.height - initialOffset))
            progress = fmax(progress, 0)
            progress = fmin(progress, 1)
        }
        
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            viewController.dismissViewControllerAnimated(true, completion: nil)
            break
            
        case .Changed:
            shouldCompleteTransition = (progress > 0.5 || gestureRecognizer.velocityInView(viewController.view).y > 200)
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
