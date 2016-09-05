//
//  ScrollableImageView.swift
//  Blicup
//
//  Created by Moymer on 9/1/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos
import Kingfisher


enum ScrollableImageViewPosAndScale: Int {
    case NONE, ASPECT_FILL, CENTER, BY_RECT
}

class ScrollableImageView: UIScrollView , UIScrollViewDelegate {
    
    private let ZOOM_FACTOR :CGFloat  = 1.2
    private let ANIM_DUR :NSTimeInterval  = 10.0
    var imageManager : PHCachingImageManager?
    private var options = PHImageRequestOptions()
    private var assets = [PHAsset]()
    
    var imageViewTrailingConstraint: NSLayoutConstraint?
    var imageViewLeadingConstraint: NSLayoutConstraint?
    var imageViewTopConstraint: NSLayoutConstraint?
    var imageViewBottomConstraint: NSLayoutConstraint?
    
    var hasBeenInit :Bool = false
    var ivScalable: UIImageView?
    
    
    private var positioningAndScale = ScrollableImageViewPosAndScale.NONE
    
    func setAssets(assets:[PHAsset]) {
        self.assets = assets
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        
        options.deliveryMode = .HighQualityFormat
        options.synchronous = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.delegate = self
    }
    
    
    internal func setImage(image : UIImage?) {
        setImage(image, key: nil)
    }
    
    
    private func setImage(image : UIImage?, key: String?) {
        if  ivScalable == nil {
            addImageView()
            
        }
        
        if image == nil {
            self.ivScalable!.image = nil
            self.ivScalable!.setNeedsLayout()
        } else {
            prepareImageForScaleAnimation(image!) { (resImage) in
                self.hasBeenInit = false
                self.ivScalable!.image = resImage
                self.ivScalable!.setNeedsLayout()
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    if key != nil {
                        KingfisherManager.sharedManager.cache.storeImage(resImage, originalData: nil, forKey: key!, toDisk: true, completionHandler: nil)
                    }
                })
            }
        }
        
    }
    internal func setImageFromUrls(thumbUrl: NSURL?, photoUrl : NSURL)
    {
        
        let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(1.0),
            .BackgroundDecode
        ]
        if  ivScalable == nil {
            addImageView()
            
        }
        if thumbUrl == nil {
            ivScalable!.kf_setImageWithURL(photoUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                self.setImage(image!,key: photoUrl.absoluteString)
            })
        }
        else {
            KingfisherManager.sharedManager.retrieveImageWithURL( thumbUrl!, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                if image == nil {
                    
                    self.ivScalable!.kf_setImageWithURL(photoUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (resImage, error, cacheType, imageURL) in
                        self.setImage(resImage!,key: photoUrl.absoluteString)
                    })
                }
                else {
                    self.ivScalable!.kf_setImageWithURL(photoUrl, placeholderImage: image, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (resImage, error, cacheType, imageURL) in
                        self.setImage(resImage!,key: photoUrl.absoluteString)
                    })
                    
                }
                
            })
        }
    }
    
    
    
    internal func setImageFromAsset(asset : PHAsset )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(1.0),
            .BackgroundDecode
            ]
            KingfisherManager.sharedManager.cache.retrieveImageForKey(asset.localIdentifier, options: optionInfo) { (resImage, cacheType) in
                if resImage != nil {
                   self.setImage(resImage!,key: asset.localIdentifier)
                } else {
                    self.imageManager?.requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.Default, options: self.options) { (resultImage, info) in
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.setImage(resultImage!,key: asset.localIdentifier)
                        }
                        
                    }
                    
                }
            }
        })
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !hasBeenInit && ivScalable?.image != nil {
            updateMinZoomScaleForSize()
            hasBeenInit = true
            positionAndScale()
        }
        
        
        
    }
    
    private func updateConstraintsForSize(size: CGSize) {
        
        let yOffset = max(0, (size.height - ivScalable!.frame.height) / 2)
        imageViewTopConstraint!.constant = yOffset
        imageViewBottomConstraint!.constant = yOffset
        
        let xOffset = max(0, (size.width - ivScalable!.frame.width) / 2)
        imageViewLeadingConstraint!.constant = xOffset
        imageViewTrailingConstraint!.constant = xOffset
        
        self.layoutIfNeeded()
    }
    
    
    private func prepareImageForScaleAnimation(image : UIImage,  completionHandler:(resImage: UIImage) -> Void ) -> Void {
        
        
        let w = UIScreen.mainScreen().bounds.width * ZOOM_FACTOR
        let h = UIScreen.mainScreen().bounds.height * ZOOM_FACTOR
        
        
        var scaledImage = image
        if image.size.width < w || image.size.height < h
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                let z = max(w/image.size.width,h/image.size.height)
                let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(z, z))
                let hasAlpha = false
                let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
                
                UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
                image.drawInRect(CGRect(origin: CGPointZero, size: size))
                
                scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(resImage: scaledImage)
                }
            })
            
        } else {
            completionHandler(resImage: scaledImage)
        }
        
        
    }
    
    private func addImageView() {
        
        ivScalable = UIImageView()
        ivScalable!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(ivScalable!)
        
        imageViewTopConstraint = NSLayoutConstraint(item: ivScalable!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        self.addConstraint(imageViewTopConstraint!)
        
        imageViewBottomConstraint = NSLayoutConstraint(item: ivScalable!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        self.addConstraint(imageViewBottomConstraint!)
        
        imageViewTrailingConstraint = NSLayoutConstraint(item: ivScalable!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        self.addConstraint(imageViewTrailingConstraint!)
        
        imageViewLeadingConstraint = NSLayoutConstraint(item: ivScalable!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        self.addConstraint(imageViewLeadingConstraint!)
        
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return ivScalable
    }
    func scrollViewDidZoom(scrollView: UIScrollView) {
        updateConstraintsForSize(self.bounds.size)
        //updateConstraintsForSize(UIScreen.mainScreen().bounds.size)
    }
    
    
    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / ivScalable!.bounds.width
        let heightScale = size.height / ivScalable!.bounds.height
        let minScale = min(widthScale, heightScale)
        
        self.minimumZoomScale = minScale
        
        
    }
    
    
    private  func updateMinZoomScaleForSize()
    {
     //   updateMinZoomScaleForSize(UIScreen.mainScreen().bounds.size)
        updateMinZoomScaleForSize(self.bounds.size)
    }
    
    
   // MARK: - Position and Scaling
    
    private func positionAndScale() {
        switch positioningAndScale {
        case ScrollableImageViewPosAndScale.ASPECT_FILL:
            makeAspectFill(false)
            break
        case ScrollableImageViewPosAndScale.CENTER:
            center(false)
            break
            
        case ScrollableImageViewPosAndScale.NONE:
            break
  
        default:
            center(false)
        }
        
        positioningAndScale = ScrollableImageViewPosAndScale.NONE
    }
    
    internal func setPositioningScale(posScale:ScrollableImageViewPosAndScale) {
        
        positioningAndScale = posScale
    }
    
    private func makeAspectFill(animated : Bool)
    {
        let w = self.superview!.bounds.width
        let h =  self.superview!.bounds.height
        
        
        let i_w = ivScalable!.bounds.width
        let i_h =  ivScalable!.bounds.height
        
        if i_w > 0 &&  i_h > 0 {
            var z : CGFloat = 1.0
            if i_w < w || i_h < h {
                //zoom in
                z = max(w/i_w, h/i_h)
                self.setZoomScale(z, animated: animated)
                
            }
            else
                if i_w > w && i_h > h{
                    //zoom out
                    z = max(w/i_w, h/i_h)
                    self.setZoomScale(z, animated: animated)
            }
            
            let new_w = i_w * z
            let new_h = i_h * z
            let offset_x = abs(new_w - w)/2
            let offset_y = abs(new_h - h)/2
            
            self.setContentOffset(CGPoint(x: offset_x, y: offset_y), animated: animated)
            
            
        }
        
    }
    
    
    
    private func center(animated : Bool)
    {
        let w = self.superview!.bounds.width
        let h =  self.superview!.bounds.height
        
        let i_w = ivScalable!.bounds.width
        let i_h =  ivScalable!.bounds.height
        
        if i_w > 0 &&  i_h > 0 {
            let offset_x = abs(i_w - w)/2
            let offset_y = abs(i_h - h)/2
            
            self.setContentOffset(CGPoint(x: offset_x, y: offset_y), animated: animated)
        }
    }
    
    // MARK: - Animating
    
    private func makeZoomInAnimation()
    {
        setZoomScale(1/ZOOM_FACTOR, animated: true)
    }
    
    
    override func setZoomScale(scale: CGFloat, animated: Bool) {
        
        if animated {
            UIView.animateWithDuration(ANIM_DUR, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                super.setZoomScale(scale, animated: false)
            }) { (fin) in
                
            }
        } else {
            super.setZoomScale(scale, animated: false)
        }
        
    }
    
}
