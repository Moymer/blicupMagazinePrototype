//
//  ChatRoomListNavigationController.swift
//  Blicup
//
//  Created by Guilherme Braga on 30/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomListNavigationController: UINavigationController {

    private let navDelegate = ChatListToCoverNavDelegate()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = navDelegate
    }

}
