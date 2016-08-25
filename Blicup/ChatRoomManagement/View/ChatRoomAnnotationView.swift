//
//  ChatRoomAnnotationView.swift
//  Blicup
//
//  Created by Moymer on 05/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import MapKit

class ChatRoomAnnotationView: MKAnnotationView {

    private let lblCount = UILabel()
    
    var chatsNumber: Int = 1 {
        didSet {
            if chatsNumber > 1 {
                lblCount.text = String(chatsNumber)
            }
            else {
                lblCount.text = nil
            }
            self.setNeedsLayout()
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clearColor()
        self.clipsToBounds = true
        setUpLabel()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
//        super.layoutSubviews()
        self.image = getAnnotationImage()
        lblCount.frame = self.bounds
    }
    
    
    private func setUpLabel() {
        lblCount.frame = self.bounds
        lblCount.backgroundColor = UIColor.clearColor()
        lblCount.textColor = UIColor.whiteColor()
        lblCount.textAlignment = NSTextAlignment.Center
        lblCount.baselineAdjustment = UIBaselineAdjustment.AlignCenters;
        lblCount.numberOfLines = 1
        lblCount.font = UIFont.boldSystemFontOfSize(16)
        lblCount.adjustsFontSizeToFitWidth = true
        
        self.addSubview(lblCount)
    }
    
    private func getAnnotationImage()->UIImage {
        var imageName = "map_circle"
        
        if (chatsNumber > 999) {
            imageName = imageName + "_4digit"
        } else if (chatsNumber > 99) {
            imageName = imageName + "_3digit"
        } else if (chatsNumber > 1) {
            imageName = imageName + "_2digit"
        }
        else {
            imageName = imageName + "_unique"
        }
        
        return UIImage(named: imageName)!
    }
}
