//
//  FullscreenVideoView.swift
//  Blicup
//
//  Created by Moymer on 9/5/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class FullscreenVideoView: UIImageView {
    var imageManager : PHCachingImageManager?
    let options = PHVideoRequestOptions()
     let optionsImage = PHImageRequestOptions()
    var avPlayer : AVPlayer?
    var avPlayerLayer : AVPlayerLayer?
    var hasInit = false
    var phAsset : PHAsset? {
        
        willSet(newPhAsset) {
            
            if self.phAsset != newPhAsset {
                removePlayer()
                if newPhAsset != nil {
                    options.deliveryMode = PHVideoRequestOptionsDeliveryMode.FastFormat
                    options.version = PHVideoRequestOptionsVersion.Original
                    
                    optionsImage.deliveryMode = .FastFormat
                    optionsImage.synchronous = false
                    self.imageManager?.requestImageForAsset(newPhAsset!, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.Default, options: optionsImage) { (resultImage, info) in
                        
                       self.image = resultImage
                       self.setNeedsLayout()
                        
                        
                        self.imageManager?.requestPlayerItemForVideo(newPhAsset!, options: self.options, resultHandler: { (avPlayerItem , infoDic) in
                            dispatch_async(dispatch_get_main_queue()) { [weak self]  in
                                if let weakSelf = self {
                                    weakSelf.avPlayer = AVPlayer(playerItem: avPlayerItem!)
                                    weakSelf.avPlayerLayer = AVPlayerLayer(player:weakSelf.avPlayer)
                                    weakSelf.avPlayerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                                    
                                    NSNotificationCenter.defaultCenter().addObserver(weakSelf,selector: #selector(FullscreenVideoView.playerItemDidReachEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: avPlayerItem)
                                    
                                    
                                    // self.avPlayerLayer!.frame = CGRectMake(0,0,self.superview!.bounds.size.width,self.superview!.bounds.size.height)
                                    
                                    weakSelf.avPlayerLayer!.frame = CGRectMake(0,0, CGFloat((weakSelf.phAsset?.pixelWidth)!), CGFloat((weakSelf.phAsset?.pixelHeight)!))
                                    
                                    // self.bounds = self.avPlayerLayer!.bounds
                                    weakSelf.layer.addSublayer(weakSelf.avPlayerLayer!)
                                    
                                    weakSelf.avPlayer!.actionAtItemEnd = AVPlayerActionAtItemEnd.None;
                                    weakSelf.avPlayer?.seekToTime(kCMTimeZero)
                                    weakSelf.avPlayer?.play()
                                    
                                    
                                }
                            }
                            
                        })
                        
                    }
                    
                    
                } else {
                    removePlayer()
                    self.image = nil
                }
                
            } else {
                self.avPlayer?.seekToTime(kCMTimeZero)
                self.avPlayer?.play()
            }

        }
        
        
    }
    
    private func removePlayer() {
        
        if self.phAsset != nil && self.avPlayerLayer != nil
        {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object:self.avPlayer?.currentItem)
            self.avPlayerLayer!.removeFromSuperlayer()
            self.avPlayerLayer = nil
            self.avPlayer = nil
        }
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        self.avPlayer?.seekToTime(kCMTimeZero)
        self.avPlayer?.play()
    }

}
