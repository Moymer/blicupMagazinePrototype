//
//  SignupViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 09/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {
    
    let welcomeVCSegue = "welcomeVC_segue"
    
    var signupPresenter: SignupPresenter!
    
    
    @IBOutlet weak var layerAnimationBtn: UIView!
    
    var userData: NSMutableDictionary?
    let vBlicupProgress: BCProgress = BCProgress()
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var pvSignup: UIProgressView!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var lblSignupStep: UILabel!
    @IBOutlet weak var btnNextBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var vContainer: UIView!
    @IBOutlet weak var containerLeadingContraint: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingContrint: NSLayoutConstraint!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startObservingKeyboardEvents()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopObservingKeyboardEvents()
    }
    
    
    @IBAction func didTapNextButton(sender: AnyObject) {
        UIView.animateWithDuration(0.3, animations: {
            self.layerAnimationBtn.hidden = true
            self.btnNext.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        }) { (_) in
            let delay = 0.1 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.signupPresenter.goToNextStep()
            }
        }
    }
    
    @IBAction func btnDragExit(sender: AnyObject) {
        UIView.animateWithDuration(0.4) {
            self.layerAnimationBtn.hidden = true
            self.btnNext.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        }
    }
    
    @IBAction func btnDragEnter(sender: AnyObject) {
        UIView.animateWithDuration(0.4) {
            self.layerAnimationBtn.hidden = false
            self.btnNext.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 14.0)
        }
    }
    
    @IBAction func btnPressedDown(sender: AnyObject) {
        UIView.animateWithDuration(0.4) {
            self.layerAnimationBtn.hidden = false
            self.btnNext.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 14.0)
            
        }
    }
    
    @IBAction func btnTouchCancel(sender: AnyObject) {
        UIView.animateWithDuration(0.4) {
            self.layerAnimationBtn.hidden = true
            self.btnNext.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        }
    }
    
    
    
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        UIView.animateWithDuration(0.3, animations: {
            self.btnBack.transform = CGAffineTransformIdentity
        }) { (_) in
            self.signupPresenter.goToPreviousStep()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let signupPageViewController = segue.destinationViewController as? SignupPageViewController {
            let presenter = SignupPresenter(signupViewController: self, userData: self.userData!)
            self.signupPresenter = presenter
            signupPageViewController.signupPresenter = presenter
            presenter.signupPageViewController = signupPageViewController
        }
    }
    
    func updateProgressView(progress: Float, step: String) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: [.CurveEaseIn], animations: { () -> Void in
            self.pvSignup.progress = progress
            self.lblSignupStep.text = step
            self.pvSignup.layoutIfNeeded()
            }, completion: nil)
    }
    
    
    private func changeBackButtonToClose(change:Bool) {
        if change {
            let image = UIImage(named: "ic_close")
            self.btnBack.setImage(image, forState: UIControlState.Normal)
        }
        else {
            let image = UIImage(named: "ic_back")
            self.btnBack.setImage(image, forState: UIControlState.Normal)
        }
    }
    
    
    func updateUIForStep(stepIndex:Int) {
        
        if stepIndex == 0 {
            self.changeBackButtonToClose(true)
            self.updateProgressView(0.33, step: "1/3")
            
        } else {
            
            if stepIndex == 1 {
                self.updateProgressView(0.66, step: "2/3")
            } else {
                self.updateProgressView(1.0, step: "3/3")
            }
            
            self.changeBackButtonToClose(false)
        }
        
        let title = stepIndex == 2 ? NSLocalizedString("UM_welcomeVC_Ok_Come_in", comment: "") : NSLocalizedString("Next", comment: "")
        self.btnNext.setTitle(title, forState: .Normal)
    }
    
    
    func showBlicLoading(showLoading:Bool) {
        if showLoading {
            vBlicupProgress.showHUDAddedTo(self.view)
        }
        else {
            vBlicupProgress.hideActivityIndicator(self.view)
        }
    }
    
    //MARK:- No internet alert
    func showNoInternetAlert() {
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Step Transitions
    func enableTransitionButton(enable:Bool) {
        self.btnNext.enabled = enable
        
        if enable {
            self.btnNext.alpha = 1.0
        }
        else {
            self.btnNext.alpha = 0.3
        }
    }
    
    func closeSignupFlow() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func animateScrollToWelcomeViewController() {
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.btnNextBottomConstraint.constant = -50
            self.containerLeadingContraint.constant = -self.vContainer.frame.width
            self.containerTrailingContrint.constant = self.vContainer.frame.width
            self.view.layoutIfNeeded()
            
        }) { (finished) -> Void in
            self.performSegueWithIdentifier(self.welcomeVCSegue, sender: nil)
        }
    }
    
    
    
    // MARK: - Keyboard
    private func startObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(self.keyboardWillShow(_:)),
                                                         name:UIKeyboardWillShowNotification,
                                                         object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(self.keyboardWillHide(_:)),
                                                         name:UIKeyboardWillHideNotification,
                                                         object:nil)
    }
    
    private func stopObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let state = UIApplication.sharedApplication().applicationState
        guard state == UIApplicationState.Active else {
            return
        }
        
        if let userInfo = notification.userInfo {
            if let keyboardSize: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size {
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.btnNextBottomConstraint.constant = keyboardSize.height
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.btnNextBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
    }
}

