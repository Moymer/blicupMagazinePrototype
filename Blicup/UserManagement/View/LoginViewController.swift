//
//  LoginViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import SafariServices

class LoginViewController: UIViewController {
    
    enum LoginStatus {
        case Error, Canceled, Success
    }
    
    var loginPresenter: LoginPresenter!
    let signupSegue = "signup_segue"
    
    @IBOutlet weak var vContainerLogo: UIView!
    @IBOutlet weak var vContainerSocialInfo: UIView!
    
    @IBOutlet weak var vLayer: UIView!
    
    let vBlicupProgress: BCProgress = BCProgress()
    
    @IBOutlet weak var btnSocialInfo: UIButton!
    @IBOutlet weak var btnCloseSocialInfo: UIButton!
    @IBOutlet weak var divisionView: UIView!
    
    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    
    @IBOutlet weak var vContainerLogoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var vContainerLogoBottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        self.loginPresenter = LoginPresenter(viewController: self)
        self.configureInitialState()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.setAnimatedBackground), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setAnimatedBackground()
    }
    
    func configureInitialState() {
        
        btnFacebook.setBackgroundColor(UIColor(hexString: "#2f3a5aff")!, forState: .Highlighted)
        btnFacebook.layer.cornerRadius = 12
        btnFacebook.clipsToBounds = true
        btnTwitter.layer.cornerRadius = 12
        btnTwitter.clipsToBounds = true
        
        divisionView.hidden = true
        btnCloseSocialInfo.hidden = true
        divisionView.alpha = 0
        btnCloseSocialInfo.alpha = 0
        
        vLayer.alpha = 0
        vLayer.hidden = true
        
    }
    
    func setAnimatedBackground() {
        let backgroundImage = UIImage(named:"login_background")!
        self.view.infiniteScrollingBackground(backgroundImage)
    }
    
    // MARK: - Actions
    
    
    @IBAction func fbLoginPressed(sender: AnyObject) {
        vBlicupProgress.showHUDAddedTo(self.view)
        
        if loginPresenter.hasInternetConnection() {
            self.loginPresenter.showFacebookLogin()
        }
        else {
            vBlicupProgress.hideActivityIndicator(self.view)
            showNoInternetAlert()
        }
        
    }
    
    @IBAction func TWTRTLoginPressed(sender: AnyObject) {
        vBlicupProgress.showHUDAddedTo(self.view)
        
        if loginPresenter.hasInternetConnection() {
            self.loginPresenter.showTwitterLogin()
        }
        else {
            vBlicupProgress.hideActivityIndicator(self.view)
            showNoInternetAlert()
        }
    }
    
    
    @IBAction func showSocialInfoPressed(sender: AnyObject) {
        
        divisionView.hidden = false
        btnCloseSocialInfo.hidden = false
        vLayer.hidden = false
        
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            
            self.divisionView.alpha = 1
            self.btnCloseSocialInfo.alpha = 1
            self.btnSocialInfo.alpha = 0
            self.vLayer.alpha = 0.6
            
            }, completion: nil)
        
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: [.CurveEaseInOut], animations: { () -> Void in
            
            self.vContainerLogoTopConstraint.constant = -self.vContainerLogo.frame.height
            self.vContainerLogoBottomConstraint.constant = screenHeight
            
            self.view.layoutIfNeeded()
            
            }, completion: nil)
        
    }
    
    
    @IBAction func hideSocialInfoPressed(sender: AnyObject) {
        
        UIView.animateWithDuration(0.2, animations: {
            self.btnCloseSocialInfo.transform = CGAffineTransformIdentity
            }, completion: { (_) in
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.divisionView.alpha = 0
                    self.btnCloseSocialInfo.alpha = 0
                    self.btnSocialInfo.alpha = 1
                    self.vLayer.alpha = 0
                    
                    }, completion: { (finished) -> Void in
                        
                        if finished {
                            self.divisionView.hidden = true
                            self.btnCloseSocialInfo.hidden = true
                            self.vLayer.hidden = true
                        }
                })
                
                
                UIView.animateWithDuration(0.5, delay: 0.0, options: [.CurveEaseInOut], animations: { () -> Void in
                    
                    self.vContainerLogoTopConstraint.constant = 0
                    self.vContainerLogoBottomConstraint.constant = screenHeight - self.vContainerLogo.frame.height
                    
                    self.view.layoutIfNeeded()
                    
                    }, completion: nil)
        })
    }
    
    
    //MARK:- No internet alert
    private func showNoInternetAlert() {
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - LoginPresenterDelegate
    func didLogin(userInfo:NSDictionary?, status:LoginStatus) {
        vBlicupProgress.hideActivityIndicator(self.view)
        
        if status == .Canceled {
            let alert = UIAlertView.init(title:NSLocalizedString("LoginCanceledTitle", comment: "Login Cancelled"), message:NSLocalizedString("LoginCanceledMessage", comment: "You need to login to use Blicup."), delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
        else if userInfo == nil || status == .Error {
            // TODO: - Tratar erro
            showNoInternetAlert()
        }
        else {
            performSegueWithIdentifier(signupSegue, sender: userInfo)
        }
    }
    
    func showNotRestoredUserDialog(message:String) {
        vBlicupProgress.hideActivityIndicator(self.view)
        
        let alert = UIAlertController(title: NSLocalizedString("Banned", comment: "You are banned") , message:NSLocalizedString("Banned_Message", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("See_Terms", comment: "See Terms"), style: UIAlertActionStyle.Default, handler: { (action) in
                let terms = NSLocalizedString("Blicup_Terms", comment: "Terms link")
                if let termsUrl = NSURL(string: terms) {
                    if #available(iOS 9.0, *) {
                        let svc = SFSafariViewController(URL: termsUrl)
                        self.presentViewController(svc, animated: true, completion: nil)
                    } else {
                        // Fallback on earlier versions
                        UIApplication.sharedApplication().openURL(termsUrl)
                    }
                }
            })
        )
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func didRestoredUser(user:User) {
        BlicupRouter.routeLogin(self.view.window)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == signupSegue {
            if let signupVc = segue.destinationViewController as? SignupViewController {
                signupVc.userData = sender as? NSMutableDictionary
            }
        }
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), color.CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, forState: forState)
    }}
