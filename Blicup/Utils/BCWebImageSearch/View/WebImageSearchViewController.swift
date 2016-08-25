//
//  WebImageSearchViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher
import RSKImageCropper

private let webImageSearchCollectionCell = "webImageSearchCollectionCell"
private let reuseCollectionFooterIdentifier = "webImageSearchCollectionFooterReusableView"

private let minInterItemSpacing: CGFloat = 5
private let collectionViewEdgeInset: CGFloat = 0
private let googleNumberOfColumns: CGFloat = 3
private let vContainerHeightDefault: CGFloat = 180

private let shadowViewDefaultAlpha: CGFloat = 0.4

enum WebImageSource: Int {
    case Giphy, Google, All
}

enum ScrollDirection {
    case ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy
}

protocol WebImageSearchViewControllerDelegate: class {
    
    func didFinishPickingWebImage(originalImage: WebImage, croppedImage: WebImage)
    
}

class WebImageSearchViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource {
    
    @IBOutlet weak var cvGiphy: UICollectionView!
    @IBOutlet weak var cvGoogle: UICollectionView!
    
    @IBOutlet weak var lblGiphyNoImagesToShow: UILabel!
    @IBOutlet weak var lblGoogleNoImagesToShow: UILabel!
    @IBOutlet weak var lblNoInternet: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var tfSearch: CustomTextField!
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    @IBOutlet weak var vLoading: UIView!
    
    @IBOutlet weak var vContainerGoogle: UIView!
    @IBOutlet weak var vContainerGoogleHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: WebImageSearchViewControllerDelegate?
    
    private var showBlicupGrayActivityIndicatorTimer: NSTimer?
    private var webImageSearchPresenter: WebImageSearchPresenter!
    
    private var lastContentOffset: CGFloat = 0
    
    private var lastSelectedImageDownloadTask: RetrieveImageDownloadTask?
    
    private var selectedWebImage : WebImage?
    
    private var googleItemSize: CGSize {
        set {
            
        }
        get {
            
            let itemWidth = ((CGRectGetWidth(self.cvGiphy!.frame) - collectionViewEdgeInset * 2) - ((googleNumberOfColumns - 1) * minInterItemSpacing)) / googleNumberOfColumns
            return CGSizeMake(itemWidth, itemWidth)
        }
    }
    
    lazy private var shadowView: UIView = {
        let view = UIView(frame: self.scrollView.frame)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = shadowViewDefaultAlpha
        return view
    }()
    
    lazy private var vBGGradient: BCGradientView = {
        let view = BCGradientView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        view.tag = 989
        return view
        
    }()
    
    lazy private var vcRSKImageCrop: RSKImageCropViewController = {
        let vcRSKImageCrop = RSKImageCropViewController()
        vcRSKImageCrop.cropMode = .Custom
        vcRSKImageCrop.delegate = self
        vcRSKImageCrop.dataSource = self
        vcRSKImageCrop.avoidEmptySpaceAroundImage = true
        
        vcRSKImageCrop.view.addSubview(self.vBGGradient)
        vcRSKImageCrop.view.bringSubviewToFront(vcRSKImageCrop.moveAndScaleLabel)
        vcRSKImageCrop.view.bringSubviewToFront(vcRSKImageCrop.chooseButton)
        vcRSKImageCrop.view.bringSubviewToFront(vcRSKImageCrop.cancelButton)
        
        return vcRSKImageCrop
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearchTextField()
        configureNoImagesToShowLabels()
        loadBlicupGrayImages()
        setTapGestureRecognizers()
        
        let presenter = WebImageSearchPresenter(vcWebImageSearch: self)
        self.webImageSearchPresenter = presenter
        
        tfSearch.performSelector(#selector(UIResponder.becomeFirstResponder), withObject: nil, afterDelay: 0.5)
        
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        
        if let lastSearch = NSUserDefaults.standardUserDefaults().objectForKey("lastSearch") as? String {
            self.tfSearch.text = lastSearch
            if lastSearch != "" {
                self.searchImagesFromPresenter(self.tfSearch)
            }
        }
    }
    
    func giphyTapIntercept(recognizer: UIGestureRecognizer) {
        
        let point = recognizer.locationInView(cvGiphy)
        if let indexPath = cvGiphy.indexPathForItemAtPoint(point) {
            collectionView(cvGiphy, didSelectItemAtIndexPath: indexPath)
        }
    }
    
    func googleTapIntercept(recognizer: UIGestureRecognizer) {
        
        let point = recognizer.locationInView(cvGoogle)
        if let indexPath = cvGoogle.indexPathForItemAtPoint(point) {
            collectionView(cvGoogle, didSelectItemAtIndexPath: indexPath)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSUserDefaults.standardUserDefaults().setObject(self.tfSearch.text, forKey: "lastSearch")
        NSObject.cancelPreviousPerformRequestsWithTarget(tfSearch, selector: #selector(UIResponder.becomeFirstResponder), object: nil)
        dismissKeyboard()
    }
    
    private func setTapGestureRecognizers() {
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(WebImageSearchViewController.dismissKeyboard))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        let giphyTap = UITapGestureRecognizer(target: self, action: #selector(WebImageSearchViewController.giphyTapIntercept(_:)))
        cvGiphy.addGestureRecognizer(giphyTap)
        
        let googleTap = UITapGestureRecognizer(target: self, action: #selector(WebImageSearchViewController.googleTapIntercept(_:)))
        cvGoogle.addGestureRecognizer(googleTap)
        
    }
    
    private func configureNoImagesToShowLabels() {
        
        lblGiphyNoImagesToShow.text = NSLocalizedString("No GIFs to show", comment: "No GIFs to show")
        lblGoogleNoImagesToShow.text = NSLocalizedString("No images to show", comment: "No images to show")
        
        lblGiphyNoImagesToShow.hidden = true
        lblGoogleNoImagesToShow.hidden = true
        
        lblNoInternet.text = NSLocalizedString("No Internet", comment: "No Internet")
        
    }
    
    private func configureSearchTextField() {
        
        let paddingX: CGFloat = 30
        let vPadding = UIView(frame: CGRect(x: 0, y: 0, width: paddingX, height: self.tfSearch.frame.height))
        let ivIconSearchPadding = UIImageView(frame: CGRectMake(10, 0, 16, self.tfSearch.frame.height))
        ivIconSearchPadding.contentMode = .ScaleAspectFit
        ivIconSearchPadding.image = UIImage(named: "ic_search")?.imageWithRenderingMode(.AlwaysOriginal)
        vPadding.addSubview(ivIconSearchPadding)
        tfSearch.paddingPosX = paddingX
        tfSearch.leftView = vPadding
        tfSearch.leftViewMode = UITextFieldViewMode.Always
        tfSearch.layer.cornerRadius = 4
        tfSearch.clipsToBounds = true
        tfSearch.placeholder = NSLocalizedString("Search Images or GIFs", comment: "Search Images or GIFs")
    }
    
    private func loadBlicupGrayImages() {
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_gray_\(index)")!)
        }
        
        ivLoadingBlicupGray.animationImages = animationArray
        ivLoadingBlicupGray.animationDuration = 1.0
        ivLoadingBlicupGray.alpha = 0
    }
    
    func showBlicLoading() {
        
        self.vLoading.hidden = false
        
        showLabelNoInternet(false)
        
        UIView.animateWithDuration(0.3, animations: {
            self.ivLoadingBlicupGray.alpha = 1
            self.vLoading.alpha = 1
            }, completion: nil)
        
        self.ivLoadingBlicupGray.startAnimating()
        
    }
    
    private func hideBlicupLoading() {
        
        UIView.animateWithDuration(0.3, animations: {
            self.ivLoadingBlicupGray.alpha = 0
            self.vLoading.alpha = 0
            }, completion: { (finished) in
                if finished {
                    self.vLoading.hidden = true
                }
        })
        
        self.ivLoadingBlicupGray.stopAnimating()
        
        invalidateShowBlicupGrayTimer()
        
    }
    
    func showLabelNoInternet(shouldShow: Bool){
        let finalAlpha: CGFloat = shouldShow ? 1.0 : 0.0
        
        self.invalidateShowBlicupGrayTimer()
        
        UIView.animateWithDuration(0.3, animations: { 
            self.ivLoadingBlicupGray.alpha = 0.0
            }) { (_) in
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                    self.lblNoInternet.alpha = finalAlpha
                }) { (_) in }
        }
    }
    
    private func invalidateShowBlicupGrayTimer() {
        if showBlicupGrayActivityIndicatorTimer != nil {
            showBlicupGrayActivityIndicatorTimer?.invalidate()
            showBlicupGrayActivityIndicatorTimer = nil
        }
    }
    
    
    func showlblNoImages(show: Bool, source: WebImageSource) {
        
        switch source {
        case .Giphy:
            self.lblGiphyNoImagesToShow.hidden = !show
            break
        case .Google:
            self.lblGoogleNoImagesToShow.hidden = !show
            break
        case .All:
            self.lblGiphyNoImagesToShow.hidden = !show
            self.lblGoogleNoImagesToShow.hidden = !show
            break
        }
        
    }
    
    
    func searchImagesFromPresenter(textField: UITextField) -> Bool{
        if let query = textField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()) {
            
            if query != webImageSearchPresenter.query {
                
                invalidateShowBlicupGrayTimer()
                showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(WebImageSearchViewController.showBlicLoading), userInfo: nil, repeats: false)
                
                webImageSearchPresenter.searchImagesWithQuery(query)
                dismissKeyboard()
                return true
            }
        }
        dismissKeyboard()
        return false
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return searchImagesFromPresenter(textField)
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        showShadowView(true)
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        showShadowView(false)
        return true
    }
    
    private func showShadowView(show: Bool) {
        
        if show {
            self.shadowView.alpha = 0
            UIView.animateWithDuration(0.3, animations: {
                self.shadowView.alpha = shadowViewDefaultAlpha
                }, completion: { (finished) in
                    self.view.insertSubview(self.shadowView, aboveSubview: self.vLoading)
            })
        } else {
            UIView.animateWithDuration(0.3, animations: {
                self.shadowView.alpha = 0
                }, completion: { (finished) in
                    self.shadowView.removeFromSuperview()
            })
        }
        
    }
    
    func dismissKeyboard() {
        if tfSearch.isFirstResponder() {
            tfSearch.resignFirstResponder()
        }
        
    }
    
    // MARK: Actions
    
    @IBAction func btnClosePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var count = 0
        switch collectionView {
        case cvGiphy:
            count = webImageSearchPresenter.giphyNumberOfItems()
            break;
        case cvGoogle:
            count = webImageSearchPresenter.googleNumberOfItems()
            break;
        default:
            break
        }
        
        return count
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionFooter {
            
            let reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: reuseCollectionFooterIdentifier, forIndexPath: indexPath) as! WebImageSearchCollectionFooterReusableView
            
            switch collectionView {
                
            // Primeira collection (Giphy)
            case cvGiphy:
                reusableView.aivLoading.hidden = webImageSearchPresenter.giphyLoading ? false : true
                break
                
            // Segunda collection (Google)
            case cvGoogle:
                
                reusableView.btnLoadMore.addTarget(webImageSearchPresenter, action: #selector(webImageSearchPresenter.loadMoreGoogleImages), forControlEvents: .TouchUpInside)
                
                if webImageSearchPresenter.googleLoading {
                    
                    reusableView.aivLoading.hidden = false
                    reusableView.btnLoadMore.hidden = true
                } else {
                    
                    reusableView.aivLoading.hidden = true
                    reusableView.btnLoadMore.hidden = webImageSearchPresenter.googlePage == webImageSearchPresenter.GOOGLE_NUMBER_MAX_PAGE ? true : false
                }
                
                break
            default:
                break
            }
            
            return reusableView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        guard let unwrappedCell = cell as? WebImageSearchCollectionViewCell else {
            return
        }
        
        unwrappedCell.imageView.kf_cancelDownloadTask()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(webImageSearchCollectionCell, forIndexPath: indexPath) as! WebImageSearchCollectionViewCell
        var webImage: WebImage?
        
        switch collectionView {
        case cvGiphy:
            webImage = webImageSearchPresenter.giphyWebImageAtIndex(indexPath.row) as WebImage
            break
            
        case cvGoogle:
            webImage = webImageSearchPresenter.googleWebImageAtIndex(indexPath.row) as WebImage
            break
            
        default:
            break
        }
        
        if let unwrappedWebImage = webImage {
            cell.imageView.kf_setImageWithURL(unwrappedWebImage.tmbUrl!, placeholderImage: nil, optionsInfo: [.PreloadAllGIFData, .Transition(.Fade(1))])
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        var webImage: WebImage?
        
        switch collectionView {
        case cvGiphy:
            
            webImage = webImageSearchPresenter.giphyWebImageAtIndex(indexPath.row) as WebImage
            break
            
        case cvGoogle:
            webImage = webImageSearchPresenter.googleWebImageAtIndex(indexPath.row) as WebImage
            break
            
        default:
            break
        }
        
        if let unwrappedWebImage = webImage {
            selectedWebImage = unwrappedWebImage
            openRSKImageCropWithImage(unwrappedWebImage)
        }
    }
    
    
    
    // MARK: UICollectionViewLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        switch collectionView {
        case cvGiphy:
            
            let webImage = webImageSearchPresenter.giphyWebImageAtIndex(indexPath.row) as WebImage
            if let webImageWidth = webImage.width, let webImageHeight = webImage.height {
                
                let imageWidth:CGFloat = (webImageWidth * collectionView.frame.height) / webImageHeight
                return CGSize(width: imageWidth, height: collectionView.frame.height)
            }
            
            return CGSize(width: 140, height: 140)
            
        case cvGoogle:
            dispatch_async(dispatch_get_main_queue(), {
                let titleHeight:CGFloat = 40
                if (self.vContainerGoogleHeightConstraint.constant - titleHeight) != collectionViewLayout.collectionViewContentSize().height {
                    self.vContainerGoogleHeightConstraint.constant = collectionViewLayout.collectionViewContentSize().height + 40
                }
            })
            
            return googleItemSize
            
        default:
            return CGSize(width: 140, height: 140)
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        switch collectionView {
        case cvGiphy:
            if webImageSearchPresenter.giphyNumberOfItems() > 0 && webImageSearchPresenter.giphyLoading {
                return CGSize(width: 50, height: collectionView.frame.height)
            }
            break
            
        case cvGoogle:
            if webImageSearchPresenter.googleNumberOfItems() > 0 && webImageSearchPresenter.googlePage < webImageSearchPresenter.GOOGLE_NUMBER_MAX_PAGE {
                return CGSize(width: collectionView.frame.width, height: 50)
            }
            break
            
        default:
            break
        }
        
        return CGSizeZero
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        var scrollDirection: ScrollDirection = .ScrollDirectionNone
        
        if (self.lastContentOffset > scrollView.contentOffset.x) {
            scrollDirection = .ScrollDirectionRight
        } else if (self.lastContentOffset < scrollView.contentOffset.x) {
            scrollDirection = .ScrollDirectionLeft
        }
        
        self.lastContentOffset = scrollView.contentOffset.x;
        
        
        if scrollDirection == .ScrollDirectionRight || scrollDirection == .ScrollDirectionLeft {
            
            let currentOffset = scrollView.contentOffset.x
            let maximumOffset = scrollView.contentSize.width - scrollView.frame.size.width
            
            if scrollView == cvGiphy {
                if (maximumOffset - currentOffset) <= -30 && !webImageSearchPresenter.giphyLoading && webImageSearchPresenter.giphyNumberOfItems() > 0 {
                    webImageSearchPresenter.loadMoreGiphyImages()
                }
            }
            
        }
    }
    
    
    func reloadCollectionView(source: WebImageSource) {
        
        switch source {
        case .Giphy:
            
            if !webImageSearchPresenter.giphyLoading {
                hideBlicupLoading()
            }
            
            self.cvGiphy.reloadData()
            break
            
        case .Google:
            
            if !webImageSearchPresenter.googleLoading {
                hideBlicupLoading()
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.cvGoogle.reloadData()
            })
            
            break
            
        case .All:
            
            scrollView.contentOffset = CGPointZero
            self.vContainerGoogleHeightConstraint.constant = vContainerHeightDefault
            self.vContainerGoogle.layoutIfNeeded()
            
            self.cvGiphy.reloadData()
            self.cvGoogle.reloadData()
            
            break
        }
        
    }
    
    
    // MARK: No internet alert
    
    func showNoInternetAlert() {
        let alert = UIAlertController(title: NSLocalizedString("NoInternetTitle", comment: "No internet") , message: NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: RSKImageCropViewController
    
    func openRSKImageCropWithImage(webImage: WebImage) {
        
        self.vBGGradient.aiView.startAnimating()
        self.vcRSKImageCrop.chooseButton.enabled = false
        
        let kfDownloader = KingfisherManager.sharedManager.downloader
        kfDownloader.downloadTimeout = 15
        
        lastSelectedImageDownloadTask = kfDownloader.downloadImageWithURL(webImage.imgUrl!, options: [.PreloadAllGIFData], progressBlock: { (receivedSize, totalSize) in
        }) { (image, error, imageURL, originalData) in
            
            if let unwrappedImage = image {
                
                self.vBGGradient.aiView.stopAnimating()
                self.vcRSKImageCrop.originalImage = unwrappedImage
                self.vcRSKImageCrop.chooseButton.enabled = true
                
            } else if let unwrappedError = error {
                
                if unwrappedError.code != -999 {
                    print(unwrappedError.code)
                    self.navigationController?.popViewControllerAnimated(true)
                    self.showNoInternetAlert()
                }
            }
        }
        
        self.navigationController?.pushViewController(vcRSKImageCrop, animated: true)
        
    }
    
    // MARK: - RSKImageCropViewControllerDelegate
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController) {
        
        if let downloadTask = lastSelectedImageDownloadTask {
            downloadTask.cancel()
        }
        
        self.navigationController?.popViewControllerAnimated(true)
        controller.originalImage = UIImage(color: UIColor.blackColor(), size: controller.view.frame.size)
    }
    
    
    func imageCropViewController(controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        
        let newCropped = WebImage(image: croppedImage, tmbUrl: self.selectedWebImage!.tmbUrl!, imgUrl: self.selectedWebImage!.imgUrl!)
        
        self.selectedWebImage?.image = controller.originalImage
        
        
        self.delegate?.didFinishPickingWebImage(self.selectedWebImage!, croppedImage: newCropped)
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
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
    
    
}


