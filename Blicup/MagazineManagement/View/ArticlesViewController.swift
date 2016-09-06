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

    var articlesController : ArticlesReadingCollectionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ArticleContentSegue" {
           articlesController = segue.destinationViewController as? ArticlesReadingCollectionViewController
            articlesController!.articleContent = articleContent
        }
        
        if segue.identifier == "ArticlePreviewControllerSegue" {
            let articlesPreviewController = segue.destinationViewController as? ArticlePreviewController
            articlesPreviewController!.mainController = self
        }
        
    }
    
    func changeLayout() {
        
        articlesController!.changeLayoutAndDesign()
    }
    
    func changeDesign() {
        
       // articlesController!.changeDesign()
    }
}



class ArticlePreviewController: UIViewController {
    
    var mainController : ArticlesViewController?
    
    @IBAction func changeLayoutDesign(sender: AnyObject) {
        mainController!.changeLayout()
    }

    @IBAction func changeMidiaPosition(sender: AnyObject) {
    
         //mainController!.changeDesign()
    }
    
    @IBAction func sendArticle(sender: AnyObject) {
    
    }
}