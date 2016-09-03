//
//  CardContentOverCollectionCell.swift
//  Blicup
//
//  Created by Moymer on 8/31/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CardContentOverCollectionCell: UICollectionViewCell {


    @IBOutlet weak var ivPhoto: ScrollableImageView!
    @IBOutlet weak var lblCardTitle: UILabel!
    @IBOutlet weak var lblCardInfoText: UILabel!
    @IBOutlet weak var vTextsContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    func setTexts(title:String, infoText:String) {
        lblCardTitle.text = title
        
        lblCardInfoText.text = infoText
        lblCardInfoText.sizeToFit()
        lblCardInfoText.layoutIfNeeded()
      
        setMockImage()
    }
    
    
    private func setMockImage()
    {
        
       ivPhoto.setImageFromUrls(nil, photoUrl: NSURL(string: "http://www.cbc.ca/documentaries/content/images/blog/greatbarrierreef1_1920.jpg")!)
        
        /**
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            let image = UIImage(named: "login_background")!
            
            dispatch_async(dispatch_get_main_queue()) {
                self.setImage(image)
            }
        })
 */

    }
    func setImage(image:UIImage)
    {
        ivPhoto.setImage(image)
       // ivPhoto.makeAspectFill(false)
    }




    /**
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        return ivPhoto
    }
 **/
}
