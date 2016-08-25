//
//  BlicupAppColors.swift
//  Blicup
//
//  Created by Guilherme Braga on 20/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation

extension UIColor {
    
    
    class func blicupPurple() -> UIColor {
        return UIColor(hexString: "#8C12FEFF")!
    }
    
    class func blicupGray() -> UIColor {
        return UIColor(hexString: "#BEBEBEFF")!
    }
    
    class func blicupGray2() -> UIColor {
        return UIColor(hexString: "#d7d7d7ff")!
    }
    
    class func blicupPink() -> UIColor {
        return UIColor(hexString: "#f70566ff")!
    }
    
    class func blicupLightGray() -> UIColor {
        return  UIColor(hexString: "#ecebedff")!
    }
    
    class func blicupLightGray2() -> UIColor {
        return UIColor(hexString: "#e0dfdbff")!
    }
    
    class func blicupLightGray3() -> UIColor {
        return UIColor(hexString: "#D0D0D0FF")!
    }
    
    class func blicupLightGray4() -> UIColor {
        return  UIColor(hexString: "#ebebebff")!
    }
    
    class func blicupGreen() -> UIColor {
        return  UIColor(hexString: "#42c9a5ff")!
    }
    
    class func blicupGreenLemon() -> UIColor {
        return UIColor(hexString: "#75ffa6ff")!
    }
    
    class func blicupBlue() -> UIColor {
        return UIColor(hexString: "#00baffff")!
    }

    class func blicupDisabledTextFieldBackgroundColor() -> UIColor {
        return UIColor(hexString: "#4e4e4eff")!.colorWithAlphaComponent(0.7)
    }
    
    class func blicupLoadingColor() -> UIColor {
        return UIColor(hexString: "#787878ff")!
    }
    
    class func blicupShareColor() -> UIColor {
        return UIColor(hexString: "#a3cde5ff")!
    }

    class func blicupFacebookHighlightedColor() -> UIColor {
        return UIColor(hexString: "#2f3a5aff")!
    }
    
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.startIndex.advancedBy(1)
            let hexColor = hexString.substringFromIndex(start)
            
            if hexColor.characters.count == 8 {
                let scanner = NSScanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexLongLong(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
    
    func rgbToInt() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            _ = Int(fAlpha * 255.0)
            
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iRed << 16) + (iGreen << 8) + iBlue
            
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
    
    class func rgbIntToUIColor(rgbValue: Int) -> UIColor {
        
        // &  binary AND operator to zero out other color values
        // >>  bitwise right shift operator
        // Divide by 0xFF because UIColor takes CGFloats between 0.0 and 1.0
        let blue =   CGFloat(rgbValue & 0xFF) / 255.0
        let green =  CGFloat((rgbValue >> 8) & 0xFF) / 255.0
        let red =   CGFloat((rgbValue >> 16) & 0xFF) / 255.0
        
        //let red =   CGFloat(rgbValue >> 16) / 0xFF
        //let green = CGFloat(rgbValue >> 8) / 0xFF
        //let blue =  CGFloat(rgbValue) / 0xFF
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    
    
}