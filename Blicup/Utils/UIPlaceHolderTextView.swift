//
//  UIPlaceHolderTextView.swift
//  Blicup
//
//  Created by Guilherme Braga on 05/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

@IBDesignable
public class UIPlaceHolderTextView: UITextView {

    private struct Constants {
        static let defaultColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
    }
    
    let placeholderLabel = UILabel()
    private let lblPlaceholderTag = 999
    
    // Placeholder text
    @IBInspectable public var placeholder: String? {

        get {
            // Get the placeholder text from the label
            var placeholderText: String?

            if let placeHolderLabel = self.viewWithTag(lblPlaceholderTag) as? UILabel {
                placeholderText = placeHolderLabel.text
            }
            return placeholderText
        }

        set {

            // Store the placeholder text in the label
            if let placeHolderLabel = self.viewWithTag(lblPlaceholderTag) as? UILabel {

                placeHolderLabel.text = newValue
                placeHolderLabel.sizeToFit()

            } else {
                // Add placeholder label to text view
                self.addPlaceholderLabel(newValue!)
            }
        }
    }
    
    
    @IBInspectable public var placeholderColor: UIColor = UIPlaceHolderTextView.Constants.defaultColor {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }
    
    override public var font: UIFont! {
        didSet {
            placeholderLabel.font = font
        }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(UIPlaceHolderTextView.textDidChange),
                                                         name: UITextViewTextDidChangeNotification,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(UIPlaceHolderTextView.textDidEndEditing),
                                                         name: UITextViewTextDidEndEditingNotification,
                                                         object: nil)
    }
    
    @objc private func textDidChange() {
        
        placeholderLabel.hidden = !text.isEmpty
    }
    
    @objc private func textDidEndEditing() {
        
        placeholderLabel.hidden = !text.isEmpty
    }
    
    // Add a placeholder label to the text view
    func addPlaceholderLabel(placeholderText: String) {

        // Create the label and set its properties
        
        placeholderLabel.text = placeholderText
        placeholderLabel.font = self.font
        placeholderLabel.sizeToFit()
        placeholderLabel.frame.origin.x = 5.0
        placeholderLabel.frame.origin.y = 5.0
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.tag = lblPlaceholderTag

        // Hide the label if there is text in the text view
        placeholderLabel.hidden = (self.text.length > 0)

        self.addSubview(placeholderLabel)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: UITextViewTextDidChangeNotification,
                                                            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: UITextViewTextDidEndEditingNotification,
                                                            object: nil)
    }

}
