//
//  Macro.swift
//  Blicup
//
//  Created by Guilherme Braga on 29/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation

let screenBounds = UIScreen.mainScreen().bounds
let screenSize   = screenBounds.size
let screenWidth  = screenSize.width
let screenHeight = screenSize.height
let navigationHeight : CGFloat = 44.0
let statubarHeight : CGFloat = 20.0
let kTabBarHeight: CGFloat = 50
let kChatRoomsListTopSectionInsetDefault: CGFloat = 75.0
let navigationHeaderAndStatusbarHeight : CGFloat = navigationHeight + statubarHeight
let kCollectionViewWaterfallEdgeInsetsDefault = UIEdgeInsetsMake(kChatRoomsListTopSectionInsetDefault, 2, 55, 2)
let kCurrentOpenChatRoomIdKey = "BlicupCurrentOpenChatRoomID"
let kIsFirstCreatedChatKey = "createdFirstChat"
let kPressChatTipKey = "pressChatTipKey"
let kPressUserTipKey = "pressUserTipKey"
let kGIFTipKey = "sendGIFTipKey"
let kMentionTipKey = "mentionTipKey"
let kCreateChatTipKey = "createChatTipKey"
let kSwipeCoverTipKey = "swipeCoverTipKey"
let kSwipeCoverImagesTipKey = "swipeCoverImagesTipKey"