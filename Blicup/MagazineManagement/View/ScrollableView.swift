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


protocol ScrollableViewDelegate {
    func changeViewScalingOrPositioning( zoom:CGFloat, offset :CGPoint) -> Void
    
}

enum ScrollableViewPosAndScale: Int {
    case NONE, ASPECT_FILL, CENTER, BY_RECT
}

class ScrollableView: UIScrollView , UIScrollViewDelegate {
    
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
    var vScalable: UIView?
    
    
    // ScrollableImageViewPosAndScale Control
    private var positioningAndScale = ScrollableViewPosAndScale.NONE
    private var viewZoom : CGFloat?
    private var viewOffset :  CGPoint?
    var zoomAndPosDelegate : ScrollableViewDelegate?
    
    
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
        
        if  vScalable == nil {
            addImageView()
        }
        
        if vScalable is UIImageView {
            
            let ivScalable = vScalable as! UIImageView
        
            if image == nil {
                ivScalable.image = nil
                ivScalable.setNeedsLayout()
            } else {
                prepareImageForScaleAnimation(image!) { (resImage) in
                    self.hasBeenInit = false
                    ivScalable.image = resImage
                    ivScalable.setNeedsLayout()
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        if key != nil {
                            KingfisherManager.sharedManager.cache.storeImage(resImage, originalData: nil, forKey: key!, toDisk: true, completionHandler: nil)
                        }
                    })
                }
            }
        }
    }
    internal func setImageFromUrls(thumbUrl: NSURL?, photoUrl : NSURL)
    {
        
        if  vScalable == nil {
            addImageView()
            
        }

        if vScalable is UIImageView {
            let ivScalable = vScalable as! UIImageView
            
            let optionInfo: KingfisherOptionsInfo = [
                .DownloadPriority(1.0),
                .BackgroundDecode
            ]
       
            if thumbUrl == nil {
                ivScalable.kf_setImageWithURL(photoUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    self.setImage(image!,key: photoUrl.absoluteString)
                })
            }
            else {
                KingfisherManager.sharedManager.retrieveImageWithURL( thumbUrl!, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                    
                    if image == nil {
                        
                        ivScalable.kf_setImageWithURL(photoUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (resImage, error, cacheType, imageURL) in
                            self.setImage(resImage!,key: photoUrl.absoluteString)
                        })
                    }
                    else {
                        ivScalable.kf_setImageWithURL(photoUrl, placeholderImage: image, optionsInfo: optionInfo, progressBlock: nil, completionHandler: { (resImage, error, cacheType, imageURL) in
                            self.setImage(resImage!,key: photoUrl.absoluteString)
                        })
                        
                    }
                    
                })
            }
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
        
        vScalable = UIImageView()
        vScalable!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(vScalable!)
        
        imageViewTopConstraint = NSLayoutConstraint(item: vScalable!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        self.addConstraint(imageViewTopConstraint!)
        
        imageViewBottomConstraint = NSLayoutConstraint(item: vScalable!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        self.addConstraint(imageViewBottomConstraint!)
        
        imageViewTrailingConstraint = NSLayoutConstraint(item: vScalable!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        self.addConstraint(imageViewTrailingConstraint!)
        
        imageViewLeadingConstraint = NSLayoutConstraint(item: vScalable!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        self.addConstraint(imageViewLeadingConstraint!)
        
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !hasBeenInit {
            if vScalable is UIImageView {
                let ivScalable = vScalable as? UIImageView
                if ivScalable?.image != nil {
                    updateMinZoomScaleForSize()
                    hasBeenInit = true
                    positionAndScale()
                }
            }
        }
        
        
    }
    
    //MARK: - Zooming
    
    private func updateConstraintsForSize(size: CGSize) {
        
        let yOffset = max(0, (size.height - vScalable!.frame.height) / 2)
        imageViewTopConstraint!.constant = yOffset
        imageViewBottomConstraint!.constant = yOffset
        
        let xOffset = max(0, (size.width - vScalable!.frame.width) / 2)
        imageViewLeadingConstraint!.constant = xOffset
        imageViewTrailingConstraint!.constant = xOffset
        
        self.layoutIfNeeded()
    }
    
    

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return vScalable
    }
    func scrollViewDidZoom(scrollView: UIScrollView) {
        updateConstraintsForSize(self.bounds.size)
        zoomAndPosDelegate?.changeViewScalingOrPositioning(self.zoomScale, offset: self.contentOffset)
        
        //updateConstraintsForSize(UIScreen.mainScreen().bounds.size)
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        zoomAndPosDelegate?.changeViewScalingOrPositioning(self.zoomScale, offset: self.contentOffset)
    }
    
    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / vScalable!.bounds.width
        let heightScale = size.height / vScalable!.bounds.height
        let minScale = max(widthScale, heightScale)
        
        self.minimumZoomScale = minScale
        self.maximumZoomScale = 3 * minScale
        
    }
    
    
    private  func updateMinZoomScaleForSize()
    {
        //updateMinZoomScaleForSize(UIScreen.mainScreen().bounds.size)
        updateMinZoomScaleForSize(self.bounds.size)
    }
    
    
    // MARK: - Position and Scaling
    
    private func positionAndScale() {
        switch positioningAndScale {
        case ScrollableViewPosAndScale.ASPECT_FILL:
            makeAspectFill(false)
            break
        case ScrollableViewPosAndScale.CENTER:
            center(false)
            break
            
        case ScrollableViewPosAndScale.BY_RECT:
            makeByRect(false)
            break
            
        default:
            center(false)
        }
        
        positioningAndScale = ScrollableViewPosAndScale.NONE
    }
    
    internal func setPositioningScale(posScale:ScrollableViewPosAndScale, zoom : CGFloat = 1.0, offset: CGPoint = CGPointZero ) {
        viewZoom = zoom
        viewOffset = offset
        positioningAndScale = posScale
    }
    private func makeAspectFill(animated : Bool)
    {
        let w = self.superview!.bounds.width
        let h =  self.superview!.bounds.height
        
        
        let i_w = vScalable!.bounds.width
        let i_h =  vScalable!.bounds.height
        
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
    
    private func makeByRect(animated : Bool)
    {
        self.setZoomScale(viewZoom!, animated: animated)
        self.setContentOffset(viewOffset!, animated: animated)
    }
    
    
    
    private func center(animated : Bool)
    {
        let w = self.superview!.bounds.width
        let h =  self.superview!.bounds.height
        
        let i_w = vScalable!.bounds.width
        let i_h =  vScalable!.bounds.height
        
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
    
    
    
    
    //MARK: - Save selected image
    
    func getImage( completionHandler:(resImage: UIImage) -> Void ) {
        
        if vScalable != nil &&  vScalable is UIImageView {
            let ivScalable = vScalable as! UIImageView
           
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                let image = ivScalable.image
                let z = self.zoomScale
                let x  = self.contentOffset.x
                let y  = self.contentOffset.y
                let visible_width  = self.vScalable?.bounds.width
                let visible_height  = self.vScalable?.bounds.height
                
                let scale_factor = 1/z
                let scaled_x = x * scale_factor
                let scaled_y = y * scale_factor
                let scaled_width = visible_width! * scale_factor
                let scaled_height = visible_height! * scale_factor
                
                
                let hasAlpha = false
                let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
                
                let size = CGSize(width: scaled_width, height: scaled_height)
                
                UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
                image!.drawInRect(CGRect(origin: CGPointMake(scaled_x, scaled_y), size: size))
                
                let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                completionHandler(resImage: scaledImage)
                
            })
        }
    }
    
}
