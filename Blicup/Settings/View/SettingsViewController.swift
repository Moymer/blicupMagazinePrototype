//
//  SettingsViewController.swift
//  Blicup
//
//  Created by Moymer on 15/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import RSKImageCropper

class SettingsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate, RSKImageCropViewControllerDelegate {
    
    private let kProfileDefaultHeight:CGFloat = 240.0
    private let kProfilePhotoOffset:CGFloat = 20.0
    private let kProfileLinesDefaultWidth:CGFloat = 260.0
    

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var ivUserPhoto: UIImageView!
    @IBOutlet weak var tfUsername: UITextField!
    @IBOutlet weak var btnUserPhoto: UIButton!
    @IBOutlet weak var lblFollowersNumber: UILabel!
    @IBOutlet weak var lblFollowingNumber: UILabel!
    @IBOutlet weak var tvDescription: UITextView!
    @IBOutlet weak var lblDescriptionPlaceholder: UILabel!

    @IBOutlet weak var btnEditProfile: UIButton!
    @IBOutlet weak var btnProfileArea: UIButton!
    @IBOutlet weak var btnEditUsername: UIButton!
    
    @IBOutlet weak var constrUsernameWidth: NSLayoutConstraint!
    @IBOutlet weak var constrUserPhotoTopDistance: NSLayoutConstraint!
    
    @IBOutlet weak var vUsernameStatus: UIView!
    @IBOutlet weak var ivUsernameStatusIcon: UIImageView!
    @IBOutlet weak var aiUsernameSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    let kVerifiedBadgeWidth: CGFloat = 15
    
    @IBOutlet var btnSaveProfile: UIButton!
    
    private let presenter = SettingsPresenter()
    private let loadingView = BCProgress()
    private var isEditing = false
    
    // MARK: - Class methods
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = " "
        
        if let navBar = self.navigationController?.navigationBar {
            navBar.tintColor = UIColor.blackColor()
            navBar.backIndicatorImage = UIImage(named: "ic_back")
            navBar.backIndicatorTransitionMaskImage = UIImage(named: "ic_back")
            navBar.barTintColor = UIColor.whiteColor()
            navBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "SFUIText-Bold", size: 18)!]
            
            let navBorder = UIView(frame: CGRectMake(0,navBar.frame.size.height,navBar.frame.size.width, 1))
            navBorder.backgroundColor = UIColor.blicupLightGray4()
            navBar.addSubview(navBorder)
        }
        
        self.collectionView.registerNib(UINib(nibName: "BlicCollectionViewCell", bundle:nil), forCellWithReuseIdentifier: "CardCell")
        
        ivUserPhoto.layer.cornerRadius = ivUserPhoto.bounds.width/2
        btnSaveProfile.hidden = true
        tvDescription.contentInset = UIEdgeInsetsZero
        
        configUsernameTF()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
        self.tabBarController?.tabBar.hidden = isEditing
        self.btnEditUsername.hidden = false
        updateUserData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenSettings()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override var inputAccessoryView: UIView? {
        return btnSaveProfile
    }

    
    // MARK: -  CollectionView Cards
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CardCell", forIndexPath: indexPath) as! BlicCollectionViewCell
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.width/3 - 15, 184.0)
    }
    
    
    
    
    
    //MARK: - Update Profile Data/Layout
    private func configUsernameTF() {
        let usernamePlaceholder = UILabel()
        usernamePlaceholder.font = tfUsername.font
        usernamePlaceholder.textColor = tfUsername.textColor
        usernamePlaceholder.text = "@"
        usernamePlaceholder.sizeToFit()
        tfUsername.leftView = usernamePlaceholder
        tfUsername.leftViewMode = UITextFieldViewMode.Always
    }
    
    private func updateUserData() {
        if isEditing {
            return
        }
        
        if let photoUrl = presenter.userPhotoUrl() {
            ivUserPhoto.kf_setImageWithURL(photoUrl)
        }
        else {
            ivUserPhoto.image = nil
        }
        
        tfUsername.text = presenter.username()
        showVerifiedBadge(presenter.isVerifiedUser())
        resizeUsernameTF()
        
        lblFollowersNumber.text = self.presenter.followersText()
        lblFollowingNumber.text = self.presenter.followeeText()
        
        tvDescription.text = presenter.userBio()
        lblDescriptionPlaceholder.text = presenter.kDefaultDescriptionMesage
        lblDescriptionPlaceholder.hidden = presenter.hasInitialBio()
        
        self.presenter.updateUserInfoData { (success) in
            if success {
                self.updateUserData()
            }
        }
    }

    @IBAction func profileAreaPressed(sender: UIButton) {
        sender.enabled = false
        self.btnEditUsername.hidden = false
        editProfilePressed(btnEditProfile)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenMyProfile()
    }
    
    @IBAction func editUsernamePressed(sender: AnyObject) {
        self.tvDescription.becomeFirstResponder()
        self.tfUsername.becomeFirstResponder()
        self.btnEditUsername.hidden = true
    }
    
    
    @IBAction func editProfilePressed(sender: UIButton) {
        isEditing = !sender.selected
        sender.selected = self.isEditing
        self.btnEditUsername.hidden = false
        // Initial State
        self.tabBarController?.tabBar.hidden = isEditing
        tfUsername.text = presenter.username()
        resizeUsernameTF()
        tvDescription.text = presenter.userBio()
        lblDescriptionPlaceholder.hidden = presenter.hasInitialBio()
        btnUserPhoto.hidden = false
        btnSaveProfile.enabled = false
        
        // Animation/Final const
        let editingAlpha:CGFloat = isEditing ? 0.0 : 1.0
        let offset = isEditing ? self.kProfilePhotoOffset : -self.kProfilePhotoOffset
        
        UIView.animateWithDuration(0.5, animations: {
            // Animation State
            self.constrUserPhotoTopDistance.constant = self.constrUserPhotoTopDistance.constant + offset
            self.btnUserPhoto.alpha = 1.0 - editingAlpha
            
            self.vUsernameStatus.alpha = 1.0 - editingAlpha
            
            self.constrUserPhotoTopDistance.constant = self.constrUserPhotoTopDistance.constant + offset
            
            self.btnUserPhoto.alpha = 1.0 - editingAlpha
            self.btnSaveProfile.alpha = 0.0
            
            self.view.layoutIfNeeded()
        
        }) { (finished) in
            // Final State
            self.vUsernameStatus.hidden = true
            self.btnSaveProfile.hidden = true
            self.btnUserPhoto.hidden = !self.isEditing
            self.tvDescription.editable = self.isEditing
            self.tfUsername.enabled = self.isEditing
            if !self.isEditing {
                self.animateImageViewBack()
                self.btnProfileArea.enabled = true
            }
        }
    }
    
    private func updateSaveBtnStatus() {
        let enable = !aiUsernameSpinner.isAnimating() && (ivUsernameStatusIcon.tag != 1) && presenter.canSaveNewData(tfUsername.text, description: tvDescription.text, newPhoto: btnUserPhoto.selected)
        
        self.btnEditUsername.hidden = false
        
        if enable !=  self.btnSaveProfile.enabled {
            btnSaveProfile.enabled = enable
            btnSaveProfile.hidden = false
            
            UIView.animateWithDuration(0.3, animations: { 
                self.btnSaveProfile.alpha = enable ? 1.0 : 0.0
                }, completion: { (_) in
                    self.btnSaveProfile.hidden = (self.btnSaveProfile.alpha == 0)
            })
        }
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
    }
    
    // MARK: - ImagePicker
    @IBAction func choosePhotoPressed(sender: UIButton) {
        self.view.endEditing(true)
        self.btnEditUsername.hidden = false
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker.delegate = self
            self.presentViewController(picker, animated: true, completion: nil)
            UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var newPhoto:UIImage?
        
        if let possibleImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            newPhoto = possibleImage
        }
        else if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            newPhoto = possibleImage
        }
        else {
            dismissPhotoPickerAnimated(nil)
            return
        }
        
        let vcRSKImagePhotoEditor = RSKImageCropViewController(image: newPhoto!)
        vcRSKImagePhotoEditor.delegate = self
        vcRSKImagePhotoEditor.avoidEmptySpaceAroundImage = true
        picker.pushViewController(vcRSKImagePhotoEditor, animated: true)
    }
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController) {
        dismissPhotoPickerAnimated(nil)
    }
    
    func imageCropViewController(controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        dismissPhotoPickerAnimated(croppedImage)
    }
    
    private func dismissPhotoPickerAnimated(newPhoto:UIImage?) {
        dismissViewControllerAnimated(true) {
            if newPhoto != nil {
                self.animatePhotoTransition(newPhoto!)
                self.btnUserPhoto.selected = true
                self.becomeFirstResponder()
            }

            self.updateSaveBtnStatus()
        }
    }
    
    
    func animateImageViewBack() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)

        let transition = CATransition()
        transition.type = kCATransitionFade
        
        ivUserPhoto.layer.addAnimation(transition, forKey: kCATransition)
        
        if let photoUrl = presenter.userPhotoUrl() {
            let image = ivUserPhoto.image
            ivUserPhoto.kf_setImageWithURL(photoUrl, placeholderImage: image, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
        }
        else {
            ivUserPhoto.image = nil
        }
        
        CATransaction.commit()
        
        btnUserPhoto.selected = false
    }
    
    private func animatePhotoTransition(photo:UIImage) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        
        let transition = CATransition()
        transition.type = kCATransitionFade
        
        ivUserPhoto.layer.addAnimation(transition, forKey: kCATransition)
        ivUserPhoto.image = photo
        
        CATransaction.commit()
    }

    
    // MARK: - TextField/TextView Delegate
    func textViewDidBeginEditing(textView: UITextView) {
        self.btnEditUsername.hidden = false
        lblDescriptionPlaceholder.hidden = true
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let finalText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        
        return (finalText.length <= 100)
    }
    
    func textViewDidChange(textView: UITextView) {
        updateSaveBtnStatus()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        lblDescriptionPlaceholder.hidden = (textView.text.length > 0)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        var newUsername = ""
        if textField.text != nil {
            newUsername = NSString(string:textField.text!).stringByReplacingCharactersInRange(range, withString: string)
        }
        else {
            newUsername = NSString(string:"").stringByReplacingCharactersInRange(range, withString: string)
        }
        
        let formattedUsername = presenter.validateIncomingUsernameEdit(newUsername)
        textField.text = formattedUsername
        
        resizeUsernameTF()
        
        vUsernameStatus.hidden = !(formattedUsername?.length>0)
        ivUsernameStatusIcon.hidden = true
        
        checkUserOnServer(formattedUsername)
        
        return false
    }
    
    private func checkUserOnServer(username:String?) {
        if username?.length > 0 && username! != presenter.username() {
            aiUsernameSpinner.startAnimating()
            updateSaveBtnStatus()
            
            presenter.checkUsernameOnServer(username!, completionHandler: { (isAvailable) in
                self.aiUsernameSpinner.stopAnimating()
                self.adjustForUsernameStatus(isAvailable)
                if self.tfUsername.text == username {
                    self.ivUsernameStatusIcon.hidden = false
                    self.updateSaveBtnStatus()
                }
            })
        }
        else {
            aiUsernameSpinner.stopAnimating()
            ivUsernameStatusIcon.hidden = true
            updateSaveBtnStatus()
        }
    }
    
    private func resizeUsernameTF() {
        if var formattedUsername = tfUsername.text {
            formattedUsername = "@" + formattedUsername // TF has a @ left view
            let maxSize = CGSizeMake(self.view.bounds.width-40, tfUsername.bounds.height)
            let calculatedSize = formattedUsername.boundingRectWithSize(maxSize, options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: [ NSFontAttributeName: tfUsername.font!], context: nil)
            
            constrUsernameWidth.constant = calculatedSize.width + 2 //tf insets compensation
        }
        else {
            constrUsernameWidth.constant = 20
        }
    }
    
    private func adjustForUsernameStatus(available:Bool) {
        if available {
            ivUsernameStatusIcon.image = UIImage(named: "ic_check")
            ivUsernameStatusIcon.tag = 0
        }
        else {
            ivUsernameStatusIcon.image = UIImage(named: "ic_not_check")
            ivUsernameStatusIcon.tag = 1
        }
    }
    
    // MARK: - Update User
    @IBAction func saveProfilePressed(sender: UIButton) {
        var userPhoto:UIImage?
        
        if btnUserPhoto.selected {
            userPhoto = ivUserPhoto.image!
        }
        
        loadingView.showHUDAddedTo(self.view)
        btnSaveProfile.enabled = false
        
        presenter.updateUser(tfUsername.text!, bio: tvDescription.text, photoImage: userPhoto) { (success) in
            self.loadingView.hideActivityIndicator(self.view)
            self.btnSaveProfile.enabled = false
            
            if success {
                self.editProfilePressed(self.btnEditProfile)
                BlicupAnalytics.sharedInstance.mark_ChangedProfile()
            }
            else {
                let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
                self.checkUserOnServer(self.tfUsername.text)
            }
        }
    }
}

//MARK: - New Class Table Controller
class ProfileTableViewController: UITableViewController {
    
    
    @IBOutlet weak var lblFavoritesNumber: UILabel!
    
    private let presenter = SettingsTablePresenter()
    private let kFolloweeSegue = "FolloweeSegue"
    private let kFollowerSegue = "FollowerSegue"
    
    private let tellAFriendCard = TellAFriendCard() // Pre-load makes share load faster
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // TELL A FRIEND
       if indexPath.row == 5 {
            tellAFriendPressed()
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tellAFriendPressed() {
        
        let image = UIImage(named: "Blicup_Banner")!
        let shareItems: Array = [self.tellAFriendCard, image]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == kFollowerSegue, let vcFollower = segue.destinationViewController as? FollowerViewController {
            if let userId = UserBS.getLoggedUser()?.userId {
                let presenter = FollowListPresenter(withUserId: userId)
                vcFollower.followPresenter = presenter
            }
        } else if segue.identifier == kFolloweeSegue, let vcFollowee = segue.destinationViewController as? FolloweeViewController {
            if let userId = UserBS.getLoggedUser()?.userId {
                let presenter = FollowListPresenter(withUserId: userId)
                vcFollowee.followPresenter = presenter
            }
        }
    }
}

class TellAFriendCard: NSObject, UIActivityItemSource {
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return ""
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        
        BlicupAnalytics.sharedInstance.mark_ToldFriend(activityType)
        
        if activityType == UIActivityTypePostToTwitter {
            return NSLocalizedString("Tell_A_Friend_Message_Twitter", comment: "tell a friend message")
        }
        
        guard let username = UserBS.getLoggedUser()?.username else { return NSLocalizedString("Tell_A_Friend_Message_Twitter", comment: "tell a friend message")}
        
        let message = NSLocalizedString("Tell_A_Friend_Message", comment: "tell a friend message")
        let messageStr  = "\(message) @\(username)"
        
        return messageStr
    }
}