//
//  LoginPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import ReachabilitySwift

class LoginPresenter: NSObject {
    
    unowned let loginVC: LoginViewController
    
    required init(viewController: LoginViewController) {
        self.loginVC = viewController
    }
    
    func showFacebookLogin() {
        LoginController.loginWithFacebook(fromController: loginVC) { (profile, error) in
            if error != nil {
                self.loginVC.didLogin(nil, status:LoginViewController.LoginStatus.Error)
            }
            else if profile != nil {
                let facebookId = profile!["facebookId"] as! String
                    UserBS.restoreFacebookUser(facebookId, completionHandler: { (status, restoredUser) in
                        if  let loggedUser = restoredUser {
                            self.loginVC.didRestoredUser(loggedUser)
                        }
                        else {
                            self.handleRestoredLogin(status, userData: profile)
                        }
                    })
            }
            else {
                self.loginVC.didLogin(nil, status:LoginViewController.LoginStatus.Canceled)
            }
        }
    }
    
    func showTwitterLogin() {
        LoginController.loginWithTwitter() { (profile, error) -> Void in
            if error != nil {
                self.loginVC.didLogin(nil, status:LoginViewController.LoginStatus.Error)
            }
            else if profile != nil {
                let twitterId = profile!["twitterId"] as! String
                    UserBS.restoreTwitterUser(twitterId, completionHandler: { (status, restoredUser) in
                        if  let loggedUser = restoredUser {
                            self.loginVC.didRestoredUser(loggedUser)
                        }
                        else {
                            self.handleRestoredLogin(status, userData: profile)
                        }
                    })
            }
            else {
                self.loginVC.didLogin(nil, status:LoginViewController.LoginStatus.Canceled)
            }
        }
    }
    
    private func handleRestoredLogin(status: LoggedUserSessionState, userData:NSDictionary?) {
        if status == LoggedUserSessionState.LoginFailed {
            self.loginVC.didLogin(nil, status:LoginViewController.LoginStatus.Error)
        }
        else if status == LoggedUserSessionState.BannedFromBlicup {
            self.loginVC.showNotRestoredUserDialog(status.rawValue)
        }
        else {
            self.loginVC.didLogin(userData, status:LoginViewController.LoginStatus.Success)
        }
    }
    
    
    func hasInternetConnection()->Bool {
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            return reachability.isReachable()
        }
        
        return false
    }
}
