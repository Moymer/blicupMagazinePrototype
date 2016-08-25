//
//  SignupUsernameViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 03/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SignupUsernameViewController: UIViewController, UITextFieldDelegate {
    
    var signupPresenter: SignupPresenter!
    
    @IBOutlet weak var tfUsername: TextFieldNoTextOptions!
    @IBOutlet weak var ivUsernameStatus: UIImageView!
    @IBOutlet weak var aiUsernameStatus: UIActivityIndicatorView!
    @IBOutlet weak var lblUsernameStatus: UILabel!
    
    @IBOutlet weak var lblVerifiedAccount: UILabel!
    @IBOutlet weak var ivVerifiedBadge: UIImageView!

    enum UsernameCheckStatus:String {
        case Available = "ic_check", NotAvailable = "ic_not_check", Checking = "no_image"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        self.configureUsernameTextField()
        self.showVerifiedBadge()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        signupPresenter.checkUsernameProceed(tfUsername.text! as String)
        tfUsername.performSelector(#selector(UIResponder.becomeFirstResponder), withObject: nil, afterDelay: 1)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequestsWithTarget(tfUsername, selector: #selector(UIResponder.becomeFirstResponder), object: nil)
        tfUsername.resignFirstResponder()
    }

    
    // MARK: - Layout
    
    func configureUsernameTextField() {
        
        let lblPadding = UILabel(frame: CGRectMake(0, 0, 20, self.tfUsername.frame.height))
        lblPadding.text = "@"
        lblPadding.textColor = UIColor.whiteColor()
        lblPadding.textAlignment = .Right
        lblPadding.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        tfUsername.leftView = lblPadding
        tfUsername.leftViewMode = UITextFieldViewMode.Always
        
        self.signupPresenter.getValidAvailableInitialUsername { (username) in
            self.tfUsername.text = username
        }
    }

    func showVerifiedBadge() {
        
        let isVerified = signupPresenter.isVerifiedUser()
        self.ivVerifiedBadge.hidden = !isVerified
        self.lblVerifiedAccount.hidden = !isVerified
    }
    
    // MARK: - Text Field Delegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if let validatedText = SignupPresenter.validateIncomingUsernameEdit(string) {
            var text:NSString = ""
            if let textFieldText = textField.text { text = textFieldText }
            
            text = text.stringByReplacingCharactersInRange(range, withString: validatedText)
            
            if text.length > USERNAME_LIMIT_LENGTH {
                text = text.substringToIndex(USERNAME_LIMIT_LENGTH)
            }
            
            textField.text = text as String
            signupPresenter.checkUsernameProceed(text as String)
        }
        
        return false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if signupPresenter.canGoToNextPage() {
            signupPresenter.goToNextStep()
        }
        
        return true
    }
    
    // MARK: - Username Validation
    func changeUsernameStatus(status:UsernameCheckStatus) {
        if status == .Checking {
            ivUsernameStatus.hidden = true
            aiUsernameStatus.startAnimating()
            lblUsernameStatus.hidden = true
        }
        else {
            aiUsernameStatus.stopAnimating()
            ivUsernameStatus.image = UIImage(named: status.rawValue)
            ivUsernameStatus.hidden = false
            lblUsernameStatus.hidden = (tfUsername.text?.length == 0 || status == .Available)
        }
    }
}
