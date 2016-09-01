//
//  CardContentOverCollectionCell.swift
//  Blicup
//
//  Created by Moymer on 8/31/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CardContentOverCollectionCell: UICollectionViewCell {

    @IBOutlet weak var ivCardPhoto: UIImageView!
    @IBOutlet weak var lblCardTitle: UILabel!
    @IBOutlet weak var lblCardInfoText: UILabel!
    @IBOutlet weak var vTextsContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setTexts(title:String, infoText:String) {
        lblCardTitle.text = title
        
        lblCardInfoText.text = infoText
        lblCardInfoText.sizeToFit()
        lblCardInfoText.layoutIfNeeded()
       
        
    }
    

}
