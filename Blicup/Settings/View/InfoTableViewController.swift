//
//  InfoTableViewController.swift
//  Blicup
//
//  Created by Moymer on 20/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import MessageUI
import SafariServices

class InfoTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    enum SelectedIndex: Int {
        case NOTIFICATIONS = 0
        case TERMS_OF_SERVICE = 2
        case PRIVACY_POLICE
        case CONTACT_US
        case LOGOUT
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = NSLocalizedString("Settings and Info", comment: "Settings and Info")
        
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.blackColor()
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    
    // MARK: Tableview Delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.row {
        case SelectedIndex.NOTIFICATIONS.rawValue:
            openSettings()
            break
        case SelectedIndex.TERMS_OF_SERVICE.rawValue:
            openTermsOfService()
            break
        case SelectedIndex.PRIVACY_POLICE.rawValue:
            openPrivacyAndPolicy()
            break
        case SelectedIndex.CONTACT_US.rawValue:
            sendEmail()
            break
        case SelectedIndex.LOGOUT.rawValue:
            logUserOut()
            break
        default:
            break
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: Settings
    func openSettings() {
        BlicupAnalytics.sharedInstance.mark_EnteredScreenNotification()
        
        guard let url = NSURL(string: UIApplicationOpenSettingsURLString) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    // MARK: Terms of Service
    func openTermsOfService() {
        BlicupAnalytics.sharedInstance.mark_EnteredScreenTermsOfUse()
        
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
    }
    
    // MARK: Privacy And Policy
    func openPrivacyAndPolicy() {
        BlicupAnalytics.sharedInstance.mark_EnteredScreenPrivacyPolicy()
        let privacy = NSLocalizedString("Blicup_Privacy", comment: "Privacy link")
        
        if let privacyUrl = NSURL(string: privacy) {
            
            if #available(iOS 9.0, *) {
                let svc = SFSafariViewController(URL: privacyUrl)
                self.presentViewController(svc, animated: true, completion: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.sharedApplication().openURL(privacyUrl)
            }
        }
    }
   
    // MARK: Mail
    func sendEmail() {
        
        let mailComposeViewController = configuredMailComposeViewController()
        
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
            BlicupAnalytics.sharedInstance.mark_ContactedBlicup()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        let username = UserBS.getLoggedUser()?.username!
        let iOSVersion = UIDevice.currentDevice().systemVersion
        let appVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
        let modelName = UIDevice.currentDevice().modelName

        let preferredLanguage = NSLocale.preferredLanguages()[0] as String
        let languageDic = NSLocale.componentsFromLocaleIdentifier(preferredLanguage)
        var locale = "en-US"
        if let languageCode = languageDic["kCFLocaleLanguageCodeKey"] {
            locale = languageCode
        }
        if let countryCode = languageDic["kCFLocaleCountryCodeKey"] {
            locale += "-\(countryCode)"
        }

        
        let bodyMessage = NSLocalizedString("ContactUs_mail_Body", comment: "E-mail body")
        let bodyUserInfo = "<div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px; line-height: normal; color: rgb(69, 69, 69);\">&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;</div><div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px; line-height: normal; color: rgb(69, 69, 69);\"><b>Username:&nbsp;</b>@\(username!)</div><div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px; line-height: normal; color: rgb(69, 69, 69);\"><b>Version:&nbsp;</b>\(appVersion)</div><div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px; line-height: normal; color: rgb(69, 69, 69);\"><b>Locale:</b>&nbsp;\(locale)</div><div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px; line-height: normal; color: rgb(69, 69, 69);\"><b>Device:&nbsp;</b>\(modelName)</div><div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px;line-height: normal; color: rgb(69, 69, 69);\"><b>iOS:&nbsp;</b>\(iOSVersion)</div><div style=\"font-family: arial, sans-serif; font-size: 13px; margin: 0px; line-height: normal; color: rgb(69, 69, 69);\">&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;</div>"
        let body = bodyMessage + bodyUserInfo
        
        mailComposerVC.setToRecipients(["help@moymer.com"])
        mailComposerVC.setSubject("Blicup \(appVersion) Feedback")
        mailComposerVC.setMessageBody(body, isHTML: true)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: Logout
    func logUserOut() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let logoutAction = UIAlertAction(title: NSLocalizedString("Logout", comment: "Log out"), style: .Default, handler: { (action) -> Void in
            self.showLogOutDialog()
        })
        
        let generalLogoutAction = UIAlertAction(title: NSLocalizedString("General_Logout", comment: "Log out from all devices"), style: .Default, handler: { (action) -> Void in
            self.showGeneralLogoutDialog()
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            print("Cancel Button Pressed")
        })
        
        alertController.addAction(logoutAction)
        alertController.addAction(generalLogoutAction)
        alertController.addAction(cancel)
        
        if #available(iOS 9.0, *) {
            logoutAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            generalLogoutAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
        alertController.view.tintColor = UIColor.blicupPink()
        
        if let subView = alertController.view.subviews.first {
            if let contentView = subView.subviews.first {
                contentView.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    private func showLogOutDialog() {
        let logOutString = NSLocalizedString("Logout", comment: "Log out")
        let logOutMessageString = NSLocalizedString("Logout_Message", comment: "Log out confirmation")
        
        let alert = UIAlertController(title: logOutString , message:logOutMessageString, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(
            UIAlertAction(title: logOutString, style: UIAlertActionStyle.Default, handler: { (action) in
                LoginController.logUserOut(LogoutReason.NormalLogout)
            })
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func showGeneralLogoutDialog() {
        let logOutString = NSLocalizedString("Logout", comment: "Log out")
        let generalLogoutString = NSLocalizedString("General_Logout", comment: "Log out from all devices")
        let logOutMessageString = NSLocalizedString("General_Logout_Message", comment: "Log out confirmation")
        
        let alert = UIAlertController(title: generalLogoutString , message:logOutMessageString, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(
            UIAlertAction(title: logOutString, style: UIAlertActionStyle.Default, handler: { (action) in
                LoginController.logUserOut(LogoutReason.PerformGeneralLogout)
            })
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
        
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
