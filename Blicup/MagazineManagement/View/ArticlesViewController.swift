//
//  ArticlesViewController.swift
//  Blicup
//
//  Created by Moymer on 9/5/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ArticlesViewController: UIViewController {

    var articleContent : [[String:AnyObject]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ArticleContentSegue" {
            let containerViewController = segue.destinationViewController as? ArticlesReadingCollectionViewController
            containerViewController!.articleContent = articleContent
        }
        
    }
    

}
