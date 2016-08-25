//
//  String Tools.swift
//  Swift String Tools
//
//  Created by Jamal Kharrat on 8/11/14.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//https://github.com/JamalK/Swift-String-Tools

import Foundation
import NSString_RemoveEmoji

extension String {
    
    //MARK: Helper methods
    
    /**
     Returns the length of the string.
     
     - returns: Int length of the string.
     */
    
    var length: Int {
        return self.characters.count
    }
    
    var objcLength: Int {
        return self.utf16.count
    }

    
    //MARK: - Linguistics
    
    /**
     Returns the langauge of a String
     
     NOTE: String has to be at least 4 characters, otherwise the method will return nil.
     
     - returns: String! Returns a string representing the langague of the string (e.g. en, fr, or und for undefined).
     */
    func detectLanguage() -> String? {
        if self.length > 4 {
            let tagger = NSLinguisticTagger(tagSchemes:[NSLinguisticTagSchemeLanguage], options: 0)
            tagger.string = self
            return tagger.tagAtIndex(0, scheme: NSLinguisticTagSchemeLanguage, tokenRange: nil, sentenceRange: nil)
        }
        return nil
    }
    
    /**
     Returns the script of a String
     
     - returns: String! returns a string representing the script of the String (e.g. Latn, Hans).
     */
    func detectScript() -> String? {
        if self.length > 1 {
            let tagger = NSLinguisticTagger(tagSchemes:[NSLinguisticTagSchemeScript], options: 0)
            tagger.string = self
            return tagger.tagAtIndex(0, scheme: NSLinguisticTagSchemeScript, tokenRange: nil, sentenceRange: nil)
        }
        return nil
    }
    
    /**
     Check the text direction of a given String.
     
     NOTE: String has to be at least 4 characters, otherwise the method will return false.
     
     - returns: Bool The Bool will return true if the string was writting in a right to left langague (e.g. Arabic, Hebrew)
     
     */
    var isRightToLeft : Bool {
        let language = self.detectLanguage()
        return (language == "ar" || language == "he")
    }
    
    
    //MARK: - Usablity & Social
    
    /**
     Check that a String is only made of white spaces, and new line characters.
     
     - returns: Bool
     */
    func isOnlyEmptySpacesAndNewLineCharacters() -> Bool {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).length == 0
    }
    
    /**
     Checks if a string is an email address using NSDataDetector.
     
     - returns: Bool
     */
    var isEmail: Bool {
        let dataDetector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        let firstMatch = dataDetector?.firstMatchInString(self, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, length))
        
        return (firstMatch?.range.location != NSNotFound && firstMatch?.URL?.scheme == "mailto")
    }
    
    /**
     Check that a String is 'tweetable' can be used in a tweet.
     
     - returns: Bool
     */
    func isTweetable() -> Bool {
        let tweetLength = 140,
        // Each link takes 23 characters in a tweet (assuming all links are https).
        linksLength = self.getLinks().count * 23,
        remaining = tweetLength - linksLength
        
        if linksLength != 0 {
            return remaining < 0
        } else {
            return !(self.utf16.count > tweetLength || self.utf16.count == 0 || self.isOnlyEmptySpacesAndNewLineCharacters())
        }
    }
    
    /**
     Gets an array of Strings for all links found in a String
     
     - returns: [String]
     */
    func getLinks() -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        
        let links = detector?.matchesInString(self, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, length)).map {$0 }
        
        return links!.filter { link in
            return link.URL != nil
            }.map { link -> String in
                return link.URL!.absoluteString
        }
    }
    
    /**
     Gets an array of URLs for all links found in a String
     
     - returns: [NSURL]
     */
    func getURLs() -> [NSURL] {
        let detector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        
        let links = detector?.matchesInString(self, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, length)).map {$0 }
        
        return links!.filter { link in
            return link.URL != nil
            }.map { link -> NSURL in
                return link.URL!
        }
    }
    
    
    /**
     Gets an array of dates for all dates found in a String
     
     - returns: [NSDate]
     */
    func getDates() -> [NSDate] {
        let error: NSErrorPointer = nil
        let detector: NSDataDetector?
        do {
            detector = try NSDataDetector(types: NSTextCheckingType.Date.rawValue)
        } catch let error1 as NSError {
            error.memory = error1
            detector = nil
        }
        let dates = detector?.matchesInString(self, options: NSMatchingOptions.WithTransparentBounds, range: NSMakeRange(0, self.utf16.count)) .map {$0 }
        
        return dates!.filter { date in
            return date.date != nil
            }.map { link -> NSDate in
                return link.date!
        }
    }
    
    /**
     Gets an array of strings (hashtags #acme) for all links found in a String
     
     - returns: [String]
     */
    func getHashtags() -> [String]? {
        let hashtagDetector = try? NSRegularExpression(pattern: "#(\\w+)", options: NSRegularExpressionOptions.CaseInsensitive)
        let results = hashtagDetector?.matchesInString(self, options: NSMatchingOptions.WithoutAnchoringBounds, range: NSMakeRange(0, self.utf16.count)).map { $0 }
        
        return results?.map({
            (self as NSString).substringWithRange($0.rangeAtIndex(1))
        })
    }
    
    /**
     Gets an array of distinct strings (hashtags #acme) for all hashtags found in a String
     
     - returns: [String]
     */
    func getUniqueHashtags() -> [String]? {
        return Array(Set(getHashtags()!))
    }
    
    
    
    /**
     Gets an array of strings (mentions @apple) for all mentions found in a String
     
     - returns: [String]
     */
    func getMentions() -> [String]? {
        let mentionDetector = try? NSRegularExpression(pattern: "@([\\w*.]*)", options: NSRegularExpressionOptions.CaseInsensitive)
        let results = mentionDetector?.matchesInString(self, options: NSMatchingOptions.WithoutAnchoringBounds, range: NSMakeRange(0, self.utf16.count)).map { $0 }
        
        return results?.map({
            (self as NSString).substringWithRange($0.rangeAtIndex(1))
        })
    }
    
    /**
     Check if a String contains a mention in it.
     
     - returns: [Sstring]
     */
    func getUniqueMentions() -> [String]? {
        return Array(Set(getMentions()!))
    }
    
    /**
     Gets an index of string (@apple) and mention found at position String
     
     - returns: [String]
     */
    func findMentionNearPosition(position: Int) -> (location: Int, mention: String) {
        let text = self
        let re = "(?<=@)[\\w*.]*"
        var match: NSTextCheckingResult? = nil
        do {
            let regexp = try NSRegularExpression(pattern: re, options:   NSRegularExpressionOptions.CaseInsensitive)
            regexp.enumerateMatchesInString(text,  options: NSMatchingOptions.WithTransparentBounds, range: NSRange(location: 0, length: text.utf16.count) , usingBlock: { (currentMatch, matchingFlag, stop: UnsafeMutablePointer<ObjCBool> ) in
                
                if currentMatch != nil {
                    if position >= currentMatch?.range.location && position <= ((currentMatch?.range.location)! + (currentMatch?.range.length)!)
                    {
                        match = currentMatch
                        stop.memory = true
                    }
                }
            })
            
        }catch let error as NSError {
            print("Error find mention: \(error)")
        }
        
        if match != nil
        {
            let s = (match?.range.location)!
            let mentionText = text as NSString
            return (s, mentionText.substringWithRange(match!.range))
        }
        return (-1,"")
    }
    
    func findArrobaNearPosition(position: Int) -> (location: Int, find: Bool) {
        let text = self
        let re = "@(?!\\s)"
        var match: NSTextCheckingResult? = nil
        do {
            let regexp = try NSRegularExpression(pattern: re, options: NSRegularExpressionOptions.CaseInsensitive)
            regexp.enumerateMatchesInString(text,  options: NSMatchingOptions.WithTransparentBounds, range: NSRange(location: 0, length: self.utf16.count) , usingBlock: { (currentMatch, matchingFlag, stop: UnsafeMutablePointer<ObjCBool> ) in
                
                if currentMatch != nil {
                    if position >= currentMatch?.range.location && position <= ((currentMatch?.range.location)! + (currentMatch?.range.length)!)
                    {
                        match = currentMatch
                        stop.memory = true
                    }
                }
            })
            
        }catch let error as NSError {
            print("Error find mention: \(error)")
        }
        
        if match != nil
        {
            let s = (match?.range.location)!
            return (s, true)
        }
        return (-1, false)
    }
 
    func convertMentionsToLinkAttributtedString(mentionList: [String]) -> NSMutableAttributedString {
        
        do {
            let attributedString = NSMutableAttributedString(string: self, attributes: ChatRoomCell.defaultAttributtedText())
            let mentionRegex = try NSRegularExpression(pattern: "@([\\w*.]*)", options: NSRegularExpressionOptions.CaseInsensitive)
            let matches = mentionRegex.matchesInString(self, options: NSMatchingOptions.WithoutAnchoringBounds, range: NSMakeRange(0, self.utf16.count))
            
            for match in matches {
                let mention = (self as NSString).substringWithRange(match.rangeAtIndex(1))
                if mentionList.contains(mention) {
                    
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blicupBlue(), range: match.rangeAtIndex(0))
                    attributedString.addAttribute(NSLinkAttributeName, value: mention, range: match.rangeAtIndex(0))
                }
            }
            
            return attributedString
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return NSMutableAttributedString()
        }
    }
    
    
    // MARK: Big Emoji
    
    func isBigEmoji() -> Bool {
        return self != "" && self.characterCount() == 1 && self.isIncludingEmoji()
    }
    
    // Obs: characters.count returns wrong number for some emojis
    func characterCount() -> Int {
        var count = 0
        enumerateSubstringsInRange(startIndex..<endIndex, options: .ByComposedCharacterSequences) {_ in count+=1}
        return count
    }
    
    /**
     Check if a String contains a link in it.
     
     - returns: Bool with true value if it does
     */
    func containsLink() -> Bool {
        return self.getLinks().count > 0
    }
    
    /**
     Check if a String contains a date in it.
     
     - returns: Bool with true value if it does
     */
    func containsDate() -> Bool {
        return self.getDates().count > 0
    }
    
    /**
     - returns: Base64 encoded string
     */
    func encodeToBase64Encoding() -> String {
        let utf8str = self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        return utf8str.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
    }
    
    /**
     - returns: Decoded Base64 string
     */
    func decodeFromBase64Encoding() -> String {
        let base64data = NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        return NSString(data: base64data!, encoding: NSUTF8StringEncoding)! as String
    }
    
    
    func wordAtIndex(index: Int) -> String {
        return (self as NSString).wordAtIndex(index) as String
    }
    
    
    // MARK: Subscript Methods
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[Range(start ..< end)]
    }
    
    subscript (range: NSRange) -> String {
        let end = range.location + range.length
        return self[range.location..<end]
    }
    
    subscript (substring: String) -> Range<String.Index>? {
        let range = startIndex..<endIndex
        return rangeOfString(substring, options: NSStringCompareOptions.LiteralSearch, range: range, locale: NSLocale.currentLocale())
    }
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    func NSRangeFromRange(range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distanceTo(from), from.distanceTo(to))
    }
    
}


extension NSString {
    
    func wordRangeAtIndex(index:Int, inString str:NSString) -> NSRange? {
        let tagger = NSLinguisticTagger(tagSchemes: [NSLinguisticTagSchemeTokenType], options: 0)
        var r : NSRange = NSMakeRange(0,0)
        tagger.string = str as String
        guard str != "" && tagger.tagAtIndex(index, scheme: NSLinguisticTagSchemeTokenType, tokenRange: &r, sentenceRange: nil) != nil else {
            return nil
        }
        return r
    }
    
    func wordAtIndex(index: Int) -> NSString {
        
        if let wordRange = wordRangeAtIndex(index, inString: self) {
            print(wordRange)
            return self.substringWithRange(wordRange)
        } else {
            return ""
        }
    }
}