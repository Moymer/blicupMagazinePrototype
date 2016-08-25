//
//  SignupTermsPrivacyViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 08/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SignupTermsPrivacyViewController: UIViewController {

    var signupPresenter: SignupPresenter!
    
    @IBOutlet weak var tvTermsAndPrivacy: UITextView!
    @IBOutlet weak var btnCheckbox: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setTermsAndPrivacyText()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.signupPresenter.termsOfUseChecked(self.btnCheckbox.selected)
    }
    
    // MARK: - Terms & Privacy
    
    func setTermsAndPrivacyText() {
        
        let htmlString = NSLocalizedString("UM_signupTermsPrivacyVc_terms&privacy", comment: "")
        tvTermsAndPrivacy.linkTextAttributes = [NSForegroundColorAttributeName : UIColor(hexString: "#f70566ff")!]
    
        do {
            
            let attrString = try NSMutableAttributedString.init(data: htmlString.dataUsingEncoding(NSUnicodeStringEncoding)!, options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType], documentAttributes: nil)
          
            attrString.addAttribute(NSFontAttributeName, value: self.tvTermsAndPrivacy.font!, range: NSMakeRange(0, attrString.length))
            tvTermsAndPrivacy.attributedText = attrString
            tvTermsAndPrivacy.textColor = UIColor.whiteColor()
            tvTermsAndPrivacy.textAlignment = NSTextAlignment.Center
            tvTermsAndPrivacy.sizeToFit()

        } catch {
            print(error)
        }
    }
    
    // MARK: - Actions
    @IBAction func btnCheckboxPressed(sender: AnyObject) {
        btnCheckbox.selected = !(sender as! UIButton).selected
        self.signupPresenter.termsOfUseChecked(self.btnCheckbox.selected)
    }

}
