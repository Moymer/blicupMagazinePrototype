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
        
        if segue.identifier == "ArticlePreviewTopControllerSegue" {
            let articlesPreviewController = segue.destinationViewController as?  ArticlePreviewTopController
            articlesPreviewController!.mainController = self
        }
        
    }
    
    func changeLayout() {
        
        articlesController!.changeLayoutAndDesign()
    }
    
    func doResizeAndRepositioning() {
        
        articlesController!.doResizeAndRepositioning()
    }
    
    
    func publishArticle() {
        
       
    }
    
    func backToEditing() {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}


//Bottom ViewController for Preview
class ArticlePreviewController: UIViewController {
    
    var mainController : ArticlesViewController?
    
    @IBOutlet weak var btnRepositioningAndResize: UIButton!
    @IBOutlet weak var btnChangeLayout: UIButton!
    @IBOutlet weak var btnSend: UIButton!
    
    @IBAction func changeLayoutDesign(sender: AnyObject) {
        mainController!.changeLayout()
    }

    @IBAction func changeMidiaPosition(sender: AnyObject) {
    
        mainController!.doResizeAndRepositioning()
        animateBts()
    }
    
    @IBAction func sendArticle(sender: AnyObject) {
    
         mainController!.publishArticle()
    }
    
    private func animateBts() {
        if !btnChangeLayout.hidden {
            
            btnChangeLayout.alpha = 1.0
            btnChangeLayout.hidden = false
            btnSend.alpha = 1.0
            btnSend.hidden = false
            
            self.btnRepositioningAndResize.transform = CGAffineTransformIdentity
            
            UIView.animateWithDuration(0.25, animations: {
                self.btnChangeLayout.alpha = 0.0
                self.btnSend.alpha = 0.0
               
                self.btnChangeLayout.hidden = true
                self.btnSend.hidden = true
                self.btnRepositioningAndResize.transform = CGAffineTransformScale( self.btnRepositioningAndResize.transform, 0.1, 0.1)
                
                },completion: { (_) in
                
                    self.btnRepositioningAndResize.setImage(UIImage(named: "Check"), forState: UIControlState.Normal)
                    UIView.animateWithDuration(0.2, animations: {
                        self.btnRepositioningAndResize.transform = CGAffineTransformIdentity
                    })
            })
            
        } else {
            btnChangeLayout.alpha = 0.0
            btnChangeLayout.hidden = false
            btnSend.alpha = 0.0
            btnSend.hidden = false
                 self.btnRepositioningAndResize.transform = CGAffineTransformIdentity
            
            UIView.animateWithDuration(0.25, animations: {
                self.btnChangeLayout.alpha = 1.0
                self.btnSend.alpha = 1.0
                self.btnRepositioningAndResize.transform = CGAffineTransformScale( self.btnRepositioningAndResize.transform, 0.1, 0.1)
                }, completion: { (_) in
            
                    self.btnRepositioningAndResize.setImage(UIImage(named: "Position"), forState: UIControlState.Normal)
                    UIView.animateWithDuration(0.2, animations: {
                        self.btnRepositioningAndResize.transform = CGAffineTransformIdentity
                    })

            })
            
     
        }
    }
    
    
}


class ArticlePreviewTopController: UIViewController {
    var mainController : ArticlesViewController?
    
    
    @IBAction func backToEditing(sender: AnyObject) {
        
        mainController!.backToEditing()
    }
    
}