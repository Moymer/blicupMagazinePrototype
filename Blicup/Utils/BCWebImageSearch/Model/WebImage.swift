//
//  WebImage.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class WebImage: NSObject {

    var tmbUrl: NSURL?
    var imgUrl: NSURL?
    var width: CGFloat?
    var height: CGFloat?
    var image: UIImage?
    init(tmbUrl: NSURL?, imgUrl: NSURL?)
    {
        super.init()
        self.tmbUrl = tmbUrl
        self.imgUrl = imgUrl
        
    }
    
    init(image:UIImage,tmbUrl: NSURL?, imgUrl: NSURL?)
    {
        self.image = image
        self.tmbUrl = tmbUrl
        self.imgUrl = imgUrl

    }
    
    init(image:UIImage)
    {
       self.image = image
        
    }

}
