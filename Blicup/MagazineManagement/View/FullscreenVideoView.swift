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

class FullscreenVideoView: UIView {
    var imageManager : PHCachingImageManager?
    let options = PHVideoRequestOptions()
    var avPlayer : AVPlayer?
    var avPlayerLayer : AVPlayerLayer?
    
    var phAsset : PHAsset? {
        
        willSet(newPhAsset) {
            
            if self.phAsset != newPhAsset {
                removePlayer()
                if newPhAsset != nil {
                    options.deliveryMode = PHVideoRequestOptionsDeliveryMode.FastFormat
                    options.version = PHVideoRequestOptionsVersion.Original
                    
                    imageManager?.requestPlayerItemForVideo(newPhAsset!, options: options, resultHandler: { (avPlayerItem , infoDic) in
                          dispatch_async(dispatch_get_main_queue()) {
                            self.avPlayer = AVPlayer(playerItem: avPlayerItem!)
                            self.avPlayerLayer = AVPlayerLayer(player:self.avPlayer)
                            self.avPlayerLayer!.videoGravity = kCAGravityResizeAspectFill
                            
                            NSNotificationCenter.defaultCenter().addObserver(self,selector: #selector(FullscreenVideoView.playerItemDidReachEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: avPlayerItem)
                            
                            self.avPlayerLayer!.frame = CGRectMake(0,0,self.bounds.size.width,self.bounds.size.height)
                            self.layer.addSublayer( self.avPlayerLayer!)
                            
                            self.avPlayer!.actionAtItemEnd = AVPlayerActionAtItemEnd.None;
                            self.avPlayer?.seekToTime(kCMTimeZero)
                            self.avPlayer?.play()
                            
                            self.setNeedsLayout()
                        }
                        
                    })
                }
                
            } else {
                self.avPlayer?.seekToTime(kCMTimeZero)
                self.avPlayer?.play()
            }
            
        }
        
        
    }
    
    private func removePlayer() {
        
        if self.phAsset != nil
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
