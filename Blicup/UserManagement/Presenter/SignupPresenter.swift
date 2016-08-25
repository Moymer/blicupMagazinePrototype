//
//  SignupPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 09/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

let USERNAME_LIMIT_LENGTH = 25

class SignupPresenter: NSObject {
    
    private let userData: NSMutableDictionary
    private var userImage:UIImage?
    
    weak var signupViewController: SignupViewController?
    weak var signupPageViewController: SignupPageViewController?
    weak var signupUsernameViewController: SignupUsernameViewController?
    weak var signupPictureViewController: SignupPictureViewController?
    weak var signupTermsPrivacyViewController: SignupTermsPrivacyViewController?
    
    
    
    private var usernameCheckTimestamp:NSTimeInterval = 0.0
    private var usernameCheckTimer:NSTimer?
    
    private var currentSignupStep:Int = 0
    
    
    required init(signupViewController: SignupViewController, userData: NSMutableDictionary) {
        self.signupViewController = signupViewController
        self.userData = userData
    }
    
    
    private func enableNextPageBtn(enable:Bool) {
        self.signupPageViewController?.enableSwipePageChange(enable)
        self.signupViewController?.enableTransitionButton(enable)
    }
    
    
    // MARK: - Username
    func getValidAvailableInitialUsername(completionHandler:(username:String?)->Void) {
        guard let username = self.userData["username"] as? String else {
            completionHandler(username: nil)
            self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.NotAvailable)
            return
        }
        
        guard let initialUsername = SignupPresenter.validateIncomingUsernameEdit(username) else {
            self.userData["username"] = nil
            completionHandler(username: nil)
            self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.NotAvailable)
            return
        }
        
        self.signupViewController?.showBlicLoading(true)
        
        generateAndCheckUsername(initialUsername) { (validUsername) in
            if validUsername != nil {
                self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.Available)
            }
            else {
                self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.NotAvailable)
            }
            
            self.enableNextPageBtn(validUsername != nil)
            self.userData["username"] = validUsername
            completionHandler(username: validUsername)
            self.signupViewController?.showBlicLoading(false)
        }
        
    }
    
    private func generateAndCheckUsername(initialUsername:String, completionHandler:(validUsername:String?)->Void) {
        UserBS.checkUsernameAvailability(initialUsername, timestamp: 0, completionHandler: { (success, isAvailable, timestamp) in
            if isAvailable {
                completionHandler(validUsername: initialUsername)
            }
            else {
                let randomUsername = self.randomNumberUsername(initialUsername)
                UserBS.checkUsernameAvailability(randomUsername, timestamp: 0, completionHandler: { (success, isAvailable, timestamp) in
                    if isAvailable {
                        completionHandler(validUsername: randomUsername)
                    }
                    else {
                        completionHandler(validUsername: nil)
                    }
                })
            }
        })
    }
    
    private func randomNumberUsername(initialUsername: String) -> String {
        let first = arc4random_uniform(10)
        let second = arc4random_uniform(10)
        
        return String(format: "%@%d%d", initialUsername, first, second)
    }
    
    class func validateIncomingUsernameEdit(text: String) -> String? {
        var replaceString = text.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
        replaceString = replaceString.stringByReplacingOccurrencesOfString(" ", withString: "_")
        replaceString = replaceString.lowercaseString
        
        if replaceString.rangeOfString("[^a-z0-9._]", options: .RegularExpressionSearch) != nil {
            return nil
        }
        
        if replaceString.length > USERNAME_LIMIT_LENGTH {
            replaceString = replaceString.substringToIndex(replaceString.startIndex.advancedBy(USERNAME_LIMIT_LENGTH))
        }
        
        return replaceString
    }
    
    func checkUsernameProceed(username:String?) {
        usernameCheckTimer?.invalidate()
        usernameCheckTimestamp = NSDate().timeIntervalSince1970
        self.enableNextPageBtn(false)
        
        self.userData["username"] = username
        
        if username != nil && username!.length > 0 {
            signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.Checking)
            usernameCheckTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(checkUsernameOnServer), userInfo: username, repeats: false)
        }
        else {
            self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.NotAvailable)
        }
    }
    
    func isVerifiedUser() -> Bool {
        guard let isVerified = self.userData["isVerified"] else {
            return false
        }
        
        return isVerified.boolValue
    }
    
    @objc private func checkUsernameOnServer(timer:NSTimer) {
        let username = timer.userInfo as! String
        
        if username.lowercaseString.containsString("blicup") || username.lowercaseString.containsString("moymer"){
            self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.NotAvailable)
        } else {
            UserBS.checkUsernameAvailability(username, timestamp: usernameCheckTimestamp, completionHandler: { (success, isAvailable, timestamp) in
                if timestamp == self.usernameCheckTimestamp {
                    self.enableNextPageBtn(isAvailable)
                    
                    if isAvailable {
                        self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.Available)
                    }
                    else {
                        self.signupUsernameViewController?.changeUsernameStatus(SignupUsernameViewController.UsernameCheckStatus.NotAvailable)
                    }
                }
            })
        }
    }
    
    
    // MARK: - Picture
    func getPictureURL()->String? {
        return self.userData["photoUrl"] as? String
    }
    
    func setChoosenImage(image:UIImage?) {
        self.userImage = image
        self.enableNextPageBtn(image != nil)
    }
    
    func validateImage() {
        self.enableNextPageBtn(self.userImage != nil)
    }
    
    
    // MARK: - Terms of Use
    func termsOfUseChecked(checked:Bool) {
        self.enableNextPageBtn(checked)
    }
    
    
    // MARK: - Page Control
    func canGoToNextPage()->Bool {
        let indexIsInRange = (self.currentSignupStep >= 0) && (self.currentSignupStep <= 2)
        return ((signupViewController?.btnNext.enabled)! && indexIsInRange)
    }
    
    func changedToPageIndex(index:Int) {
        self.currentSignupStep = index
        self.signupViewController?.updateUIForStep(index)
    }
    
    func goToNextStep() {
        if signupViewController?.btnNext.enabled == false {
            return
        }
        
        self.enableNextPageBtn(false)
        
        switch self.currentSignupStep {
            
        case 0, 1:
            self.signupPageViewController?.scrollToPageIndex(self.currentSignupStep+1, isNext:true)
            break
        case 2:
            validateAndCreateUser()
            break
        default :
            break
        }
        
    }
    
    func goToPreviousStep() {
        if currentSignupStep >= 1 {
            self.signupPageViewController?.scrollToPageIndex(self.currentSignupStep-1, isNext: false)
        }
        else {
            self.signupViewController?.closeSignupFlow()
        }
    }
    
    
    
    // MARK: - Finished Filling Profile
    func validateAndCreateUser() {
        self.signupViewController?.showBlicLoading(true)
        
        AmazonManager.uploadImageToAmazonBucket(self.userImage!, key: "userImage") { (urlImagem) in
            if urlImagem != nil {
                self.userData["photoUrl"] = urlImagem
                UserBS.createUserAccount(self.userData) { (success, newUser) in
                    if success {
                        if newUser != nil { self.scrollToWelcomeViewController() }
                        else { self.signupPageViewController?.scrollToPageIndex(0, isNext:false) }
                    }
                    else {
                        // TODO: - Tratar erro
                        dispatch_async(dispatch_get_main_queue(),{
                            self.signupViewController?.showNoInternetAlert()
                            self.enableNextPageBtn(true)
                        })
                    }
                    dispatch_async(dispatch_get_main_queue(),{
                        self.signupViewController?.showBlicLoading(false)
                    })
                }
            }
            else {
                // TODO: - Tratar erro
                
                dispatch_async(dispatch_get_main_queue(),{
                    self.signupViewController?.showBlicLoading(false)
                    self.signupViewController?.showNoInternetAlert()
                    self.enableNextPageBtn(true)
                })
            }
        }
    }
    
    func scrollToWelcomeViewController() {
        self.signupTermsPrivacyViewController?.view.userInteractionEnabled = false
        self.signupViewController?.view.userInteractionEnabled = false
        self.signupPageViewController?.view.userInteractionEnabled = false
        
        self.signupViewController?.animateScrollToWelcomeViewController()
    }
}
