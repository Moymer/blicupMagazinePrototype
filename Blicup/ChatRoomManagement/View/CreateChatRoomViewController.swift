//
//  CreateChatRoomViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 05/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreLocation
import RSKImageCropper
import FBSDKShareKit
import Photos


class CreateChatRoomViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource, WebImageSearchViewControllerDelegate, CLLocationManagerDelegate, FBSDKSharingDelegate, UIScrollViewDelegate, HandleMapSearch {
    
    var createChatRoomPresenter: CreateChatRoomPresenter!
    
    var activeField: UIView?
    var keyboardHeight: CGFloat = 300
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    @IBOutlet weak var vContainerButtonsShare: UIView!
    
    @IBOutlet var lblShareTwitter: UILabel!
    @IBOutlet weak var ivShareTwitter: UIImageView!
    @IBOutlet weak var constrLblTwitterWidth: NSLayoutConstraint!
    @IBOutlet weak var constrLblTwitterHeight: NSLayoutConstraint!
    
    @IBOutlet weak var lblShareFacebook: UILabel!
    @IBOutlet weak var ivShareFacebook: UIImageView!
    @IBOutlet weak var constrLblFacebookWidth: NSLayoutConstraint!
    @IBOutlet weak var constrLblFacebookHeight: NSLayoutConstraint!
    
    @IBOutlet weak var layerAnimationBtn: UIView!
    let vBlicupProgress: BCProgress = BCProgress()
    var cgPointBtnCreate: CGPoint?
    var parentView: UIViewController!
    
    @IBOutlet weak var tvChatTitleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tvChatDescriptionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var vInputAccessoryView: CreateChatRoomInputAccessoryView!
    
    @IBOutlet weak var tvChatTitle: UIPlaceHolderTextView!
    @IBOutlet weak var tvChatTags: UIPlaceHolderTextView!
    
    @IBOutlet weak var divisao1: UIView!
    @IBOutlet weak var divisao2: UIView!
    
    @IBOutlet weak var btnDismissView: UIButton!
    
    @IBOutlet weak var cvcCoverPhotosContainer: UIView!
    @IBOutlet weak var cvcCoverPhotosContainerWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var vBlackLayer: UIView!
    @IBOutlet weak var ivBackgroundImage: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var btnCreateChat: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var btnLocation: UIButton!
    
    let modelName = UIDevice.currentDevice().modelName
    
    @IBOutlet weak var lblCustomLocation: UILabel!
    var customLocation: CLLocationCoordinate2D? = nil
    
    var selectedImage :WebImage?
    
    var indexOfSelected : Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateChatRoomViewController.willExpandView), name: "animationExpandDidStopCircleSegue", object: nil)
        
        configureComponentsToBeAnimated()
        scrollView.delegate = self
        tvChatTitle.placeholder = NSLocalizedString("CRM_createChatRoomVC_chat_title", comment: "")
        tvChatTags.placeholder = NSLocalizedString("CRM_createChatRoomVC_chat_#tags", comment: "")
        btnCreateChat .setTitle(NSLocalizedString("Create chat", comment: "Create chat"), forState: .Normal)
        vBlackLayer.hidden = true
        
        if !deviceWithSmallScreen() {
            scrollView.scrollEnabled = false
        }
        
        self.lblShareTwitter.layer.cornerRadius = 5
        self.lblShareTwitter.clipsToBounds = true
        
        self.lblShareFacebook.layer.cornerRadius = 5
        self.lblShareFacebook.clipsToBounds = true
        
        let hideLocationOption = !createChatRoomPresenter.hasLocationBtnTag()
        btnLocation.hidden = hideLocationOption
        lblCustomLocation.hidden = hideLocationOption
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(0.2) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            t = CGAffineTransformScale(t, 1, 1)
            self.btnDismissView.transform = t
        }
        
        if ivBackgroundImage.image != nil {
            UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let inputView = self.inputAccessoryView as? CreateChatRoomInputAccessoryView {
            inputView.showBtnCreateChat(self.canCreateChatRoom())
        }
        
        self.startObservingKeyboardEvents()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "animationExpandDidStopCircleSegue", object: nil)
        self.stopObservingKeyboardEvents()
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    override var inputAccessoryView: UIView? {
        
        vInputAccessoryView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
        return vInputAccessoryView
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // MARK: - SetUp
    
    func configureComponentsToBeAnimated(){
        tvChatTitle.transform = CGAffineTransformMakeScale(0, 0)
        tvChatTags.transform = CGAffineTransformMakeScale(0, 0)
        
        btnTwitter.transform = CGAffineTransformMakeScale(0, 0)
        btnFacebook.transform = CGAffineTransformMakeScale(0, 0)
        btnLocation.transform = CGAffineTransformMakeScale(0, 0)
        
        divisao1.transform = CGAffineTransformMakeScale(0, 0)
        divisao2.transform = CGAffineTransformMakeScale(0, 0)
        
        cvcCoverPhotosContainer.transform = CGAffineTransformMakeScale(0, 0)
        
        var t = CGAffineTransformIdentity
        t = CGAffineTransformRotate(t, CGFloat((M_PI * 45) / 180))
        t = CGAffineTransformScale(t, 0.4, 0.4)
        btnDismissView.transform = t
    }
    
    func deviceWithSmallScreen() -> Bool{
        if UIScreen.mainScreen().nativeBounds.size == CGSize(width: 640.0, height: 960.0) || UIScreen.mainScreen().nativeBounds.size == CGSize(width: 640.0, height: 1136.0){
            return true
        }
        return false
    }
    
    func willExpandView(){
        UIView.animateWithDuration(0.25) {
            self.tvChatTitle.transform = CGAffineTransformMakeScale(1, 1)
            self.tvChatTags.transform = CGAffineTransformMakeScale(1, 1)
            
            self.btnTwitter.transform = CGAffineTransformMakeScale(1, 1)
            self.btnFacebook.transform = CGAffineTransformMakeScale(1, 1)
            self.btnLocation.transform = CGAffineTransformMakeScale(1, 1)
            
            self.divisao1.transform = CGAffineTransformMakeScale(1, 1)
            self.divisao2.transform = CGAffineTransformMakeScale(1, 1)
            
            self.cvcCoverPhotosContainer.transform = CGAffineTransformMakeScale(1, 1)
            self.tvChatTitle.becomeFirstResponder()
        }
        
    }
    
    //MARK: HandleMapSearch Delegate
    func setLocation(coordinate: CLLocationCoordinate2D?, title: String?){
        if coordinate == nil && title == nil{
            self.btnLocation.selected = false
            self.lblCustomLocation.hidden = true
        } else {
            self.btnLocation.selected = true
            self.lblCustomLocation.text = title
            self.lblCustomLocation.hidden = false
            self.customLocation = coordinate
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func btnPhotoPressed(sender: AnyObject) {
        presentActionSheet()
    }
    
    @IBAction func btnDragExit(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 1, 1)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnDismissView.transform = t
        }
    }
    
    @IBAction func btnDragEnter(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 0.7, 0.7)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnDismissView.transform = t
        }
    }
    
    @IBAction func btnPressedDown(sender: AnyObject) {
        UIView.animateWithDuration(0.2) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 0.7, 0.7)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnDismissView.transform = t
        }
    }
    
    @IBAction func btnTouchCancel(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 1, 1)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnDismissView.transform = t
        }
    }
    
    func presentActionSheet() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let photoLibrary = UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: .Default, handler: { (action) -> Void in
            
            self.openPhotoLibrary()
        })
        
        let webSearch = UIAlertAction(title: NSLocalizedString("Web Search", comment: ""), style: .Default, handler: { (action) -> Void in
            
            self.openWebImageSearch()
            
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            if let inputView = self.inputAccessoryView as? CreateChatRoomInputAccessoryView {
                inputView.showBtnCreateChat(self.canCreateChatRoom())
            }
        })
        
        if #available(iOS 9.0, *) {
            photoLibrary.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            webSearch.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        
        alertController.addAction(photoLibrary)
        alertController.addAction(webSearch)
        alertController.addAction(cancel)
        
        self.hideKeyboard()
        
        // Wait for keyboard to dismiss to avoid the strange behavior of keyboard with black buttons
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.presentViewController(alertController, animated: true, completion: nil)
            
            alertController.view.tintColor = UIColor.blicupPink()
            
            if let subView = alertController.view.subviews.first {
                if let contentView = subView.subviews.first {
                    contentView.backgroundColor = UIColor.whiteColor()
                }
            }
        })
    }
    
    
    @IBAction func btnCreateChatPressed(sender: AnyObject) {
        self.btnCreateChat.userInteractionEnabled = false
        UIView.animateWithDuration(0.3, animations: {
            self.layerAnimationBtn.hidden = true
            self.btnCreateChat.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 16.0)
            self.handleLocationStatus(CLLocationManager.authorizationStatus())
        })
        
    }
    
    
    @IBAction func btnDragExitCreateChat(sender: AnyObject) {
        UIView.animateWithDuration(0.3) {
            self.layerAnimationBtn.hidden = true
            self.btnCreateChat.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        }
    }
    
    @IBAction func btnDragEnterCreateChat(sender: AnyObject) {
        UIView.animateWithDuration(0.3) {
            self.layerAnimationBtn.hidden = false
            self.btnCreateChat.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 14.0)
        }
    }
    
    @IBAction func btnPressedDownCreateChat(sender: AnyObject) {
        UIView.animateWithDuration(0.3) {
            self.layerAnimationBtn.hidden = false
            self.btnCreateChat.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 14.0)
            
        }
    }
    
    @IBAction func btnTouchCancelCreateChat(sender: AnyObject) {
        UIView.animateWithDuration(0.3) {
            self.layerAnimationBtn.hidden = true
            self.btnCreateChat.titleLabel?.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        }
    }
    
    
    @IBAction func closePressed(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("lastSearch")
        UIView.animateWithDuration(0.1, animations: {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 1, 1)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnDismissView.transform = t
        }) { (_) in
            UIView.animateWithDuration(0.2, animations: {
                self.tvChatTitle.transform = CGAffineTransformMakeScale(0, 0)
                self.tvChatTags.transform = CGAffineTransformMakeScale(0, 0)
                
                self.btnTwitter.transform = CGAffineTransformMakeScale(0, 0)
                self.btnFacebook.transform = CGAffineTransformMakeScale(0, 0)
                self.btnLocation.transform = CGAffineTransformMakeScale(0, 0)
                
                self.divisao1.transform = CGAffineTransformMakeScale(0, 0)
                self.divisao2.transform = CGAffineTransformMakeScale(0, 0)
                
                self.btnCreateChat.transform = CGAffineTransformMakeScale(0, 0)
                
                self.cvcCoverPhotosContainer.transform = CGAffineTransformMakeScale(0, 0)
                
                self.lblShareTwitter.transform = CGAffineTransformMakeScale(0, 0)
                self.ivShareTwitter.transform = CGAffineTransformMakeScale(0, 0)
                
                self.lblShareFacebook.transform = CGAffineTransformMakeScale(0, 0)
                self.ivShareFacebook.transform = CGAffineTransformMakeScale(0, 0)
                
                var t = CGAffineTransformIdentity
                t = CGAffineTransformRotate(t, CGFloat((M_PI * 45) / 180))
                t = CGAffineTransformScale(t, 0.5, 0.5)
                self.btnDismissView.transform = t
                
                self.hideKeyboard()
                }, completion: { (_) in
                    self.btnDismissView.enabled = false
                    let segue = OHCircleSegue(identifier: "unwindToPreviousController", source: self, destination: self.parentView)
                    segue.circleOrigin = self.cgPointBtnCreate!
                    self.prepareForSegue(segue, sender: self)
                    segue.perform()
                    
            })
        }
    }
    
    
    @IBAction func btnLocationPressed(sender: AnyObject) {
        if self.btnLocation.selected {
            self.customLocation = nil
            self.btnLocation.selected = false
            self.lblCustomLocation.hidden = true
        } else {
            let searchLocationView = self.storyboard?.instantiateViewControllerWithIdentifier("searchLocationNavigationController") as? UINavigationController
            let searchLocationVC = searchLocationView?.childViewControllers.first as? SearchLocationTableViewController
            searchLocationVC?.handleMapSearchDelegate = self
            self.presentViewController(searchLocationView!, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnTwitterPressed(sender: UIButton) {
        
        if self.btnTwitter.selected {
            
            self.btnTwitter.selected = false
            createChatRoomPresenter.publishToTwitter(false)
            self.showTwitterCallout(false)
        } else {
            
            if self.tvChatTags.isFirstResponder() || self.tvChatTitle.isFirstResponder() {
                self.hideKeyboard()
                
                // Wait for keyboard to dismiss to avoid the strange behavior of keyboard with black buttons
                let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
                dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                    self.checkTwitterPublishPermissions()
                })
            } else {
                self.checkTwitterPublishPermissions()
            }
        }
    }
    
    func checkTwitterPublishPermissions() {
        
        self.createChatRoomPresenter.checkTwitterPublishPermissions { (publishPermissionsResult) in
            
            switch (publishPermissionsResult) {
            case .Error: break // TODO: tratar erro
                
            case .Canceled, .Declined:
                
                let alert = UIAlertController(title: NSLocalizedString("TwitterSharePermissionCanceledTitle", comment: "Couldn’t share on Twitter"), message: NSLocalizedString("TwitterSharePermissionCanceledMessage", comment: "To share your chat with your friends you have to connect to Twitter."), preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                
                break
                
            case .Success:
                self.btnTwitter.selected = true
                self.showTwitterCallout(true)
                self.createChatRoomPresenter.publishToTwitter(true)
                break
            }
        }
    }
    
    @IBAction func btnFacebookPressed(sender: UIButton) {
        
        if self.btnFacebook.selected {
            
            self.btnFacebook.selected = false
            createChatRoomPresenter.publishToFacebook(false)
            
            self.showFacebookCallout(false)
            
        } else {
            
            if self.tvChatTags.isFirstResponder() || self.tvChatTitle.isFirstResponder() {
                
                self.hideKeyboard()
                
                // Wait for keyboard to dismiss to avoid the strange behavior of keyboard with black buttons
                let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
                dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                    self.checkFacebookPublishPermissions()
                })
                
            } else {
                self.checkFacebookPublishPermissions()
            }
        }
    }
    
    func checkFacebookPublishPermissions() {
        
        self.createChatRoomPresenter.checkFacebookPublishPermissions { (publishPermissionsResult) in
            
            switch (publishPermissionsResult) {
            case .Error: break // TODO: tratar erro
                
            case .Canceled, .Declined:
                
                let alert = UIAlertController(title: NSLocalizedString("FacebookSharePermissionCanceledTitle", comment: "Couldn’t share on Facebook"), message: NSLocalizedString("FacebookSharePermissionCanceledMessage", comment: "To share your chat with your friends you have to connect to Facebook."), preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                
                break
                
            case .Success:
                
                self.btnFacebook.selected = true
                self.showFacebookCallout(true)
                self.createChatRoomPresenter.publishToFacebook(true)
                break
            }
        }
    }
    
    @IBAction func handleTapGesture(sender: AnyObject) {
        self.hideKeyboard()
    }
    
    func hideKeyboard() {
        
        if tvChatTitle.isFirstResponder() {
            
            self.tvChatTitle.resignFirstResponder()
            
        } else if tvChatTags.isFirstResponder() {
            
            self.tvChatTags.resignFirstResponder()
            
        }
        scrollView.setContentOffset(CGPointZero, animated: true)
    }
    
    //MARK: - Show Callout Shares
    func showFacebookCallout(on: Bool){
        
        let result = self.createChatRoomPresenter.textForShareCallout(on, socialMedia: CreateChatRoomPresenter.SocialMedia.FACEBOOK.rawValue)
        self.lblShareFacebook.attributedText = result.text
        self.constrLblFacebookWidth.constant = result.size.width
        self.constrLblFacebookHeight.constant = result.size.height
        
        UIView.animateWithDuration(1, animations: {
            
            self.lblShareFacebook.alpha = 1
            self.ivShareFacebook.alpha = 1
            self.lblShareFacebook.layoutIfNeeded()
            
            }, completion: { (_) in
                UIView.animateWithDuration(1, delay: 0.5, options: [], animations: {
                    self.lblShareFacebook.alpha = 0
                    self.ivShareFacebook.alpha = 0
                    }, completion: { (_) in
                        
                })
        })
    }
    
    func showTwitterCallout(on: Bool){
        
        let result = self.createChatRoomPresenter.textForShareCallout(on, socialMedia: CreateChatRoomPresenter.SocialMedia.TWITTER.rawValue)
        self.lblShareTwitter.attributedText = result.text
        self.constrLblTwitterWidth.constant = result.size.width
        self.constrLblTwitterHeight.constant = result.size.height
        
        UIView.animateWithDuration(1, animations: {
            
            self.lblShareTwitter.alpha = 1
            self.ivShareTwitter.alpha = 1
            self.lblShareTwitter.layoutIfNeeded()
            
            }, completion: { (_) in
                UIView.animateWithDuration(1, delay: 0.5, options: [], animations: {
                    self.ivShareTwitter.alpha = 0
                    self.lblShareTwitter.alpha = 0
                    }, completion: { (_) in
                        
                })
        })
    }
    
    // MARK: - Picture
    
    func openPhotoLibrary() {
        
        indexOfSelected = self.createChatRoomPresenter.numberOfCoverPhotos()
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker.delegate = self
            self.presentViewController(picker, animated: true, completion: nil)
            UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        }
    }
    
    
    func openRSKImageCropWithImage(image : WebImage, picker: UIImagePickerController?) {
        
        let vcRSKImageCrop = RSKImageCropViewController(image: image.image!, cropMode: .Custom)
        vcRSKImageCrop.delegate = self
        vcRSKImageCrop.dataSource = self
        vcRSKImageCrop.avoidEmptySpaceAroundImage = true
        
        let view = BCGradientView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        vcRSKImageCrop.view.addSubview(view)
        vcRSKImageCrop.view.bringSubviewToFront(vcRSKImageCrop.moveAndScaleLabel)
        vcRSKImageCrop.view.bringSubviewToFront(vcRSKImageCrop.chooseButton)
        vcRSKImageCrop.view.bringSubviewToFront(vcRSKImageCrop.cancelButton)
        
        if self.createChatRoomPresenter.isImageEditing {
            self.presentViewController(vcRSKImageCrop, animated: true, completion: nil)
        } else {
            picker?.pushViewController(vcRSKImageCrop, animated: true)
        }
    }
    
    
    func openRSKImageCropToEditingSelectedImage(sender : UIButton) {
        
        self.hideKeyboard()
        indexOfSelected = sender.tag
        self.selectedImage = createChatRoomPresenter.originalImageAtIndex(indexOfSelected)
        createChatRoomPresenter.beginEditingImageAtIndex(indexOfSelected)
        openRSKImageCropWithImage(self.selectedImage!, picker: nil)
    }
    
    
    func openWebImageSearch() {
        
        indexOfSelected = self.createChatRoomPresenter.numberOfCoverPhotos()
        
        let storyboard = UIStoryboard(name: "WebImageSearch", bundle: nil)
        if let vcWebImageSourceNav = storyboard.instantiateViewControllerWithIdentifier("WebImageSearchNav") as? UINavigationController {
            if let vcWebImageSource = vcWebImageSourceNav.viewControllers.first as? WebImageSearchViewController{
                vcWebImageSource.delegate = self
                self.presentViewController(vcWebImageSourceNav, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        var newImage = UIImage()
        
        if let possibleUrl = info["UIImagePickerControllerReferenceURL"] as? NSURL {
            let asset: PHAsset = PHAsset.fetchAssetsWithALAssetURLs([possibleUrl], options: nil).lastObject as! PHAsset
            let options = PHImageRequestOptions()
            options.synchronous = true
            options.networkAccessAllowed = false
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: options) { (imageData, dataUTI, orientation, info) in
                if let _ = imageData {
                    newImage = Image.blic_imageWithData(imageData!, scale: 1.0, preloadAllGIFData: true)!
                } else {
                    return
                }
            }
        } else {
            return
        }
        
        openRSKImageCropWithImage(WebImage(image: newImage), picker: picker)
    }
    
    
    func updatePhotosContainer() {
        
        self.cvcCoverPhotosContainerWidthConstraint.constant = (createChatRoomPresenter.cvcCoverPhotos.collectionView?.collectionViewLayout.collectionViewContentSize().width)!
        
        UIView.animateWithDuration(0.3) {
            self.cvcCoverPhotosContainer.layoutIfNeeded()
        }
    }
    
    func selectedPicture(image: WebImage?) {
        
        if indexOfSelected == 0
        {
            if let selectedImage = image {
                createChatRoomPresenter.setImageBgMain(selectedImage)
                ivBackgroundImage.image = selectedImage.image!
                vBlackLayer.hidden = false
            }
        }
    }
    
    func reloadBGImageWithImage(imageBG: WebImage?) {
        
        if createChatRoomPresenter.numberOfCoverPhotos() > 0 {
            self.ivBackgroundImage.image = imageBG?.image!
        } else {
            self.ivBackgroundImage.image = nil
            vBlackLayer.hidden = true
        }
    }
    
    
    // MARK: - RSKImageCropViewControllerDelegate
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController) {
        
        if self.createChatRoomPresenter.isImageEditing {
            self.createChatRoomPresenter.imageFinishedEditing()
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            controller.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    
    func imageCropViewController(controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        
        var newCropped : WebImage
        var originalImage : WebImage
        if self.selectedImage != nil
        {
            newCropped = WebImage(image: croppedImage, tmbUrl: self.selectedImage?.tmbUrl, imgUrl: self.selectedImage?.imgUrl)
            originalImage = WebImage(image: controller.originalImage, tmbUrl: self.selectedImage?.tmbUrl, imgUrl: self.selectedImage?.imgUrl)
        }
        else
        {
            newCropped = WebImage(image: croppedImage)
            originalImage = WebImage(image: controller.originalImage)
        }
        
        
        self.createChatRoomPresenter.didFinishPickingImage(newCropped, originalImage: originalImage)
        self.selectedPicture(newCropped)
        self.dismissViewControllerAnimated(true, completion: nil)
        showCreateChatBtn()
        
    }
    
    
    func imageCropViewControllerCustomMaskRect(controller: RSKImageCropViewController) -> CGRect {
        
        let maskRect = CGRect(x: 0, y: 0, width: screenBounds.size.width, height: screenBounds.size.height);
        
        return maskRect
    }
    
    func imageCropViewControllerCustomMaskPath(controller: RSKImageCropViewController) -> UIBezierPath {
        
        let rect = controller.maskRect
        let fullScreenArea =  UIBezierPath(rect: rect)
        
        return fullScreenArea
    }
    
    func imageCropViewControllerCustomMovementRect(controller: RSKImageCropViewController) -> CGRect {
        return controller.maskRect
    }
    
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChangeSelection(textView: UITextView) {
        
        let range = textView.selectedRange
        
        // Tentou editar em qualquer posição do texto que não seja no fim
        if range.location < textView.text.length {
            
            let index: String.Index = textView.text.startIndex.advancedBy(range.location)
            let stringAtRange = textView.text.substringToIndex(index)
            
            // Para quando o usuário segurar o delete e for apagando mais de 1 letra por vez
            if stringAtRange.characters.last == "#" && textView.text.length > 1 {
                
                // Verifica se a próxima é um # para não deixar ele começar um texto no intervalo entre " " e #
                if let nextIndex: String.Index = textView.text.startIndex.advancedBy(range.location + 1) {
                    let nextString = textView.text.substringToIndex(nextIndex)
                    if nextString.characters.last == "#" {
                        textView.selectedRange = NSRange(location: range.location - 1, length: range.length - 1)
                    }
                    
                }
            }
            
        }
        
    }
    
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        // Apertou return
        if text == "\n" {
            
            if textView == self.tvChatTitle && self.tvChatTags.text == "" {
                
                self.tvChatTags.becomeFirstResponder()
                
            } else {
                
                textView.resignFirstResponder()
            }
            
            return false
        }
        
        
        let newLenght = textView.text.characters.count + (text.characters.count - range.length)
        
        // tratamento para textView das Tags
        if textView == self.tvChatTags && newLenght < self.createChatRoomPresenter.TAGS_LIMIT_LENGHT{
            
            // Tentou apagar o Hashtag inicial ou escrever algo no iniício
            if range.location == 0 { return false }
            
            // Apertou espaço
            if text == " " {
                
                if textView.text.characters.last != "#" {
                    textView.text.appendContentsOf(" #")
                }
                
                return false
            }
            
            // Apertou delete
            if text == "" {
                
                let lastCharacter = textView.text.characters.last
                
                if lastCharacter == "#" || lastCharacter == " " {
                    textView.text = removeLastCharacterHashtagAndWhiteSpace(textView.text)
                    return false
                }
            }
        }
        
        
        let charactersLimit = textView == self.tvChatTitle ? self.createChatRoomPresenter.TITLE_LIMIT_LENGHT : self.createChatRoomPresenter.TAGS_LIMIT_LENGHT
        
        return newLenght <= charactersLimit
    }
    
    func textViewDidChange(textView: UITextView) {
        
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        textView.frame = newFrame;
        
        if textView == self.tvChatTitle {
            
            self.tvChatTitleHeightConstraint.constant = newFrame.height
            
        } else if textView == self.tvChatTags {
            
            self.tvChatDescriptionHeightConstraint.constant = newFrame.height
        }
        
        if deviceWithSmallScreen() {
            var contentInsets: UIEdgeInsets!
            if UIScreen.mainScreen().nativeBounds.size == CGSize(width: 640.0, height: 960.0) {
                contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.vContainerButtonsShare.frame.midY - keyboardHeight + self.vContainerButtonsShare.frame.height + self.btnCreateChat.frame.height, right: 0)
            } else {
                contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.vContainerButtonsShare.frame.minY - keyboardHeight + self.vContainerButtonsShare.frame.height, right: 0)
            }
            
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
        
        showCreateChatBtn()
        
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        
        if textView == tvChatTags && textView.text.length < createChatRoomPresenter.TAGS_LIMIT_LENGHT {
            
            if textView.text == "" {
                textView.text = "#"
            } else if textView.text.characters.last != "#" {
                textView.text.appendContentsOf(" #")
            }
        }
        
        if deviceWithSmallScreen(){
            if !(UIScreen.mainScreen().nativeBounds.size == CGSize(width: 640.0, height: 1136.0)) {
                if textView == tvChatTitle{
                    scrollView.setContentOffset(CGPoint(x: 0.0, y: CGPointZero.y + 20), animated: true)
                } else{
                    let scrollPoint = CGPoint(x: 0.0, y: 120.0)
                    scrollView.setContentOffset(scrollPoint, animated: true)
                }
            }
        }
        
        activeField = textView
        
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        
        if textView == tvChatTags {
            textView.text = removeLastCharacterHashtagAndWhiteSpace(textView.text)
        }
        
        
        if textView == activeField { activeField = nil }
        
        return true
    }
    
    
    func removeLastCharacterHashtagAndWhiteSpace(text: String) -> String{
        
        var newText = text
        
        if newText.characters.last == "#" {
            newText = String(newText.characters.dropLast())
        }
        
        newText = newText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        return newText
    }
    
    // MARK: WebImageSearchViewControllerDelegate
    
    func didFinishPickingWebImage(originalImage: WebImage, croppedImage: WebImage) {
        
        self.createChatRoomPresenter.didFinishPickingImage(croppedImage, originalImage: originalImage)
        self.selectedPicture(croppedImage)
        
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "CoverPhotosEmbedSegue" {
            
            if let cvcCoverPhotos = segue.destinationViewController as? CoverPhotosCollectionViewController {
                
                let vCreateChatRoom = self
                let presenter = CreateChatRoomPresenter(vCreateChatRoom: vCreateChatRoom, cvcCoverPhotos: cvcCoverPhotos)
                self.createChatRoomPresenter = presenter
                cvcCoverPhotos.createChatRoomPresenter = presenter
            }
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
        
        if deviceWithSmallScreen() {
            if self.tvChatTitle.isFirstResponder() || self.tvChatTags.isFirstResponder() {
                self.scrollView.scrollEnabled = true
            }
        }
        
        if let userInfo = notification.userInfo {
            if let kbSize: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size {
                
                keyboardHeight = kbSize.height
                
                var contentInsets: UIEdgeInsets!
                
                if UIScreen.mainScreen().nativeBounds.size == CGSize(width: 640.0, height: 960.0) {
                    contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.vContainerButtonsShare.frame.midY - keyboardHeight + self.vContainerButtonsShare.frame.height + self.btnCreateChat.frame.height, right: 0)
                } else {
                    contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.vContainerButtonsShare.frame.minY - keyboardHeight + self.vContainerButtonsShare.frame.height, right: 0)
                }
                
                scrollView.contentInset = contentInsets
                scrollView.scrollIndicatorInsets = contentInsets
                
                var aRect = self.view.frame
                aRect.size.height -= keyboardHeight - btnCreateChat.frame.height + CGFloat(20)
                
                if activeField != nil && !CGRectContainsPoint(aRect, self.btnFacebook.frame.origin) {
                    let scrollPoint = CGPoint(x: 0.0, y: self.btnFacebook.frame.origin.y + self.btnFacebook.frame.height - keyboardHeight)
                    scrollView.setContentOffset(scrollPoint, animated: true)
                }
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if deviceWithSmallScreen() {
            self.scrollView.scrollEnabled = false
        }
        
        self.scrollView.contentInset = UIEdgeInsetsZero
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    
    func showCreateChatBtn()  {
        
        let canShowCreateChatBtn = canCreateChatRoom()
        
        if activeField != nil && canShowCreateChatBtn {
            
            //            if deviceWithSmallScreen() {
            //                if !tvChatTags.isFirstResponder(){
            //                    let scrollPoint = CGPoint(x: 0.0, y: 120.0 + btnTwitter.frame.height)
            //                    scrollView.setContentOffset(scrollPoint, animated: true)
            //                }else{
            //                    let scrollPoint = CGPoint(x: 0.0, y: 105.0 + btnTwitter.frame.height )
            //                    scrollView.setContentOffset(scrollPoint, animated: true)
            //                }
            //            }
        }
        
        if let inputView = self.inputAccessoryView as? CreateChatRoomInputAccessoryView {
            inputView.showBtnCreateChat(canShowCreateChatBtn)
        }
        
    }
    
    func canCreateChatRoom() -> Bool {
        
        return createChatRoomPresenter.numberOfCoverPhotos() > 0 && !tvChatTags.text.isEmpty && tvChatTags.text != "#" && !tvChatTitle.text.isEmpty
    }
    
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        handleLocationStatus(status)
    }
    
    func handleLocationStatus(status: CLAuthorizationStatus) {
        
        switch status {
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            if canCreateChatRoom() {
                locationManager.startUpdatingLocation()
            }
            break
            
        case .Denied, .Restricted:
            self.btnCreateChat.userInteractionEnabled = true
            showNeedsPermissionAlert()
            break
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            // TODO: tratar não conseguiu pegar location
            self.btnCreateChat.userInteractionEnabled = true
            let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        
        showBlicLoading(true)
        
        UIView.animateWithDuration(0.2) {
            self.layerAnimationBtn.hidden = false
            self.layerAnimationBtn.alpha = 0.4
        }
        
        var chatLocation: CLLocation!
        
        if self.customLocation == nil{
            chatLocation = location
        } else {
            chatLocation = CLLocation(latitude: self.customLocation!.latitude, longitude: self.customLocation!.longitude)
        }
        
        createChatRoomPresenter.validateAndCreateChat(tvChatTags.text, name: tvChatTitle.text, location: chatLocation, completionHandler: { (success, chatRoom) in
            
            self.showBlicLoading(false)
            
            UIView.animateWithDuration(0.2) {
                self.layerAnimationBtn.hidden = true
                self.layerAnimationBtn.alpha = 0.3
            }
            
            self.locationManager.delegate = self
            
            if success  && chatRoom != nil {
                //self.closePressed(self.btnDismissView)
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: kIsFirstCreatedChatKey)
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: chatRoom!.chatRoomId!)
                BlicupRouter.routeCreateChatRoomBackToChat(self, chatRoomId: chatRoom!.chatRoomId!)
            }
            else {
                let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
                self.btnCreateChat.userInteractionEnabled = true
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        self.btnCreateChat.userInteractionEnabled = true
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //MARK:- Denied Location Permission Alert
    
    private func showNeedsPermissionAlert() {
        let alert = UIAlertController(title:NSLocalizedString("CRM_LocationPermissions_Title", comment: "Location Permissions Required") , message:NSLocalizedString("CRM_LocationPermissions_Message", comment: "Blicup needs permission to access your location just to show your brand new chat on the map. Click the Settings button, then go to Location and select the While Using the App option."), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .Default, handler: { (action) in
            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.sharedApplication().openURL(url)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // Blicup Loading
    
    func showBlicLoading(showLoading:Bool) {
        if showLoading {
            vBlicupProgress.showHUDAddedTo(self.view)
        }
        else {
            vBlicupProgress.hideActivityIndicator(self.view)
        }
    }
    
    
    // Facebook Share Delegate
    func sharerDidCancel(sharer: FBSDKSharing!) {
        print("FB share cancelado")
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        print("FB share falhou")
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("FB share sucesso")
    }
}
