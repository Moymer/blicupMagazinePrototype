//
//  ArticlePreviewPresenter.swift
//  Blicup
//
//  Created by Moymer on 9/7/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit


class ArticlePreviewPresenter: NSObject {

    var onRepositioning = false

    var midiasRepositionings :  [Int : [String: ArticleCardMidiaPositioning]] = [:]

    func addArticleCardMidiaPositioning(pos : ArticleCardMidiaPositioning, cardMode: CardMode) {
        
        if onRepositioning {
            var  positioningsForMode = midiasRepositionings[cardMode.rawValue]
            if positioningsForMode ==  nil {
                positioningsForMode = [:]
               
            }
            positioningsForMode![pos.assetKey!] = pos
            midiasRepositionings[cardMode.rawValue] = positioningsForMode
        }
    }
    
    func getArticleCardMidiaPositioning(key : String, cardMode: CardMode)  -> ArticleCardMidiaPositioning? {
        if let positioningsForMode = midiasRepositionings[cardMode.rawValue] {
            return positioningsForMode[key]
        }
        return nil
    }
    
}

class ArticleCardMidiaPositioning: NSObject {
    
    var zoom : CGFloat?
    var offset : CGPoint?
    var assetKey : String?
    
    convenience init(z : CGFloat,o : CGPoint?,  k : String? ) {
        self.init()
        
        self.zoom = z
        self.offset = o
        self.assetKey = k
    }
}
