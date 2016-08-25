//
//  WelcomeViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 11/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    var ivBlicupLogo: UIImageView?
    var lblWelcome: UILabel?
    var lblFavoritesTitle: UILabel?
    var lblFavoritesHashtags: UILabel?
    
    @IBOutlet weak var ivListOfFavorites: UIImageView!
    @IBOutlet weak var ivBackground: UIImageView!
 
    @IBOutlet weak var btnBottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.startWelcomeAnimation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Fade)
    }

    
    // MARK: - Create Views
    
    func createBlicupLogo() -> UIImageView {
        
        let imageView = UIImageView.init(image: UIImage(named: "Blic30_0"))
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "Blic30_\(index)")!)
        }
        
        imageView.animationImages = animationArray
        imageView.animationDuration = 1.0
        imageView.center = self.view.center
        imageView.center.y = self.view.frame.height
        self.view.addSubview(imageView)
        
        return imageView
    }
    
    func createWelcomeLabel() -> UILabel {
        
        let label = UILabel.init(frame: CGRectMake(0, 0, 200, 50))
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        label.text = NSLocalizedString("Welcome", comment: "") + "!"
        label.font = UIFont(name: "SFUIText-Light", size: 24.0)
        label.sizeToFit()
        label.frame.size.height += 5
        label.center = self.view.center
        label.center.y += 75
        label.alpha = 0.0
        
//        Ajustando Anchor Point para rotacionar a base e não o meio da view
        label.setAnchorPoint(CGPoint(x: 0.5, y: 1.0))
        
        var lblWelcomeRotate = CATransform3DMakeRotation(CGFloat(M_PI_2), 1.0, 0.0, 0.0)
        lblWelcomeRotate.m34 = -1.0 / 500.0;
        label.layer.transform = lblWelcomeRotate
        
        return label
    }

    func createFavoritesTitleLabel() -> UILabel {
        
        let title = NSLocalizedString("UM_welcomeVC_favoritesTitle", comment: "") as String
        let subtitle = NSLocalizedString("UM_welcomeVC_favoritesSubtitle", comment: "")
    
        let myString = title + "\n\n" + subtitle
        let attrString = NSMutableAttributedString(string: myString, attributes: [NSFontAttributeName:UIFont(name: "SFUIText-Regular", size: 16.0)!])
        attrString.addAttribute(NSFontAttributeName, value: UIFont(name: "SFUIText-Bold", size: 18.0)!, range:NSRange(location: 0, length: title.characters.count))
        
        let labelFavoritesTitle = UILabel.init(frame: CGRectMake(0, -500, screenWidth - 20
            , 300))
        labelFavoritesTitle.textColor = UIColor.whiteColor()
        labelFavoritesTitle.textAlignment = .Center
        labelFavoritesTitle.numberOfLines = 0
        labelFavoritesTitle.attributedText = attrString
        labelFavoritesTitle.sizeToFit()
        labelFavoritesTitle.hidden = true
        labelFavoritesTitle.center.x = self.view.center.x
        self.view.addSubview(labelFavoritesTitle)
        
        return labelFavoritesTitle
    }
    
    func createFavoritesHashtagsLabel() -> UILabel {
        
        let title = NSLocalizedString("UM_welcomeVC_hashtags", comment: "") as String
        let subtitle = NSLocalizedString("UM_welcomeVC_hashtags_description", comment: "")
        
        let myString = title + "\n\n" + subtitle
        let attrString = NSMutableAttributedString(string: myString, attributes: [NSFontAttributeName:UIFont(name: "SFUIText-Regular", size: 16.0)!])
        attrString.addAttribute(NSFontAttributeName, value: UIFont(name: "SFUIText-Bold", size: 18.0)!, range:NSRange(location: 0, length: title.characters.count))
        
        let labelFavoritesHashtags = UILabel.init(frame: CGRectMake(0, screenHeight + 300, screenWidth - 20
            , 300))
        labelFavoritesHashtags.textColor = UIColor.whiteColor()
        labelFavoritesHashtags.textAlignment = .Center
        labelFavoritesHashtags.numberOfLines = 0
        labelFavoritesHashtags.attributedText = attrString
        labelFavoritesHashtags.sizeToFit()
        labelFavoritesHashtags.hidden = true
        labelFavoritesHashtags.center.x = self.view.center.x
        self.view.addSubview(labelFavoritesHashtags)
        
        return labelFavoritesHashtags
    }

    // MARK: - Animations
    
    func startWelcomeAnimation() {
        
        self.ivBlicupLogo = self.createBlicupLogo()
        self.lblWelcome = self.createWelcomeLabel()
        self.ivBackground.addSubview(lblWelcome!)
        self.ivBackground.bringSubviewToFront(lblWelcome!)
        self.ivBackground.layoutSubviews()
        
        
        let screenHeight = self.view.frame.height
        let swinAnimateY = (screenHeight/2) / 4
       
        
        ivBlicupLogo!.startAnimating()
        self.animateBlicupLogoRecursive(ivBlicupLogo!, swinAnimateY: swinAnimateY)
       
        //1.0 delay 3.0
        UIView.animateWithDuration(0.7, delay: 3.0, options: [.CurveLinear], animations: { () -> Void in
            
            // Rotate Welcome UILabel and scale
            self.lblWelcome!.alpha = 1.0
            let lblWelcomeRotate = CATransform3DMakeRotation(0, 1, 0, 0)
            let lblWelcomeScale = CATransform3DMakeScale(1.2, 1.2, 1.2)
            self.lblWelcome!.layer.transform = CATransform3DConcat(lblWelcomeRotate, lblWelcomeScale)
            
        }) { (finished) -> Void in
            
            if finished {
                // Scale Welcome Label
                UIView.animateWithDuration(3.0, animations: { () -> Void in
                    let lblWelcomeScale2 =  CATransform3DMakeScale(1.25, 1.25, 1)
                    self.lblWelcome!.layer.transform = CATransform3DConcat(self.lblWelcome!.layer.transform, lblWelcomeScale2)
                }, completion: { (finished) -> Void in

                    if finished {
                        
                        // Hidden Welcome and BlicupLogo
                        UIView.animateWithDuration(1.0, animations: { () -> Void in
                            self.lblWelcome!.alpha = 0.0
                            self.ivBlicupLogo!.alpha = 0.0
                        }, completion: { (finished) -> Void in
                            
                            // Start List Of Favorites Animation
                            if finished {
                                self.animateListOfFavorites()
                            }
                        })
                    }
                })
            }
        }
    }
    
    
    func animateBlicupLogoRecursive(ivBlicupLogo: UIImageView, swinAnimateY: CGFloat) {
        
        UIView.animateWithDuration(0.8, delay: 0.0, options:[.CurveEaseInOut], animations: { () -> Void in
            
            ivBlicupLogo.frame.origin.y -= (swinAnimateY + 10)
            self.view.layoutIfNeeded()
            
        }) { (finished) -> Void in
                
            if finished {
            
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    
                ivBlicupLogo.frame.origin.y += 5
                    
                }, completion: { (finished) -> Void in
                        
                    if ivBlicupLogo.frame.origin.y + 10 <= self.view.center.y {
                        return
                    } else {
                        self.animateBlicupLogoRecursive(ivBlicupLogo, swinAnimateY: swinAnimateY)
                    }
                })
            }
        }
    }

    
    func animateListOfFavorites() {
        
        self.lblFavoritesTitle = self.createFavoritesTitleLabel()
        self.lblFavoritesTitle?.hidden = false
        
        self.lblFavoritesHashtags = self.createFavoritesHashtagsLabel()
        self.lblFavoritesHashtags?.hidden = false
        
        self.ivListOfFavorites.transform = CGAffineTransformMakeScale(0.6, 0.6)
        self.ivListOfFavorites.alpha = 0.0
        self.ivListOfFavorites.hidden = false
        
        UIView.animateWithDuration(1.0, delay: 1.0, options: [], animations: { () -> Void in
            
            self.ivListOfFavorites.transform = CGAffineTransformIdentity
            self.ivListOfFavorites.alpha = 1.0
            
            if let lblFavoritesTitleHeight = self.lblFavoritesTitle?.frame.height {
                let lblFavoritesTitleOriginY = self.ivListOfFavorites.frame.origin.y - lblFavoritesTitleHeight - 35
                self.lblFavoritesTitle?.frame.origin.y = lblFavoritesTitleOriginY
            }
            

            let lblFavoritesHashtagsOriginY = self.ivListOfFavorites.frame.origin.y + self.ivListOfFavorites.frame.height + 15
            self.lblFavoritesHashtags?.frame.origin.y = lblFavoritesHashtagsOriginY
            
            
            }, completion: { (finished) -> Void in
                
                self.btnBottomConstraint.constant = 0
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        })
    }
    
    // MARK: - Actions
    
    @IBAction func btnNextPressed(sender: AnyObject) {
        
        self.performSegueWithIdentifier("welcome_to_interest_segue", sender: nil)
    }

}


extension UILabel {
    
    func setAnchorPoint(anchorPoint: CGPoint) {
        var newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x, self.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x, self.bounds.size.height * self.layer.anchorPoint.y)
        
        newPoint = CGPointApplyAffineTransform(newPoint, self.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform)
        
        var position = self.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        self.layer.position = position
        self.layer.anchorPoint = anchorPoint
    }
}