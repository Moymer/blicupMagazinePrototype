//
//  SearchViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 29/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var btnSearchBar: BCButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        btnSearchBar.layer.cornerRadius = btnSearchBar.frame.height/2
        btnSearchBar.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func searchPressed(sender: AnyObject) {
        
        self.view.userInteractionEnabled = false
        btnSearchBar.transform = CGAffineTransformMakeScale(0.95, 0.95)
        UIView.animateWithDuration(0.3, animations: {
            self.btnSearchBar.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.performSegueWithIdentifier("showChatRoomAndUserSearchSegue", sender: nil)
            self.view.userInteractionEnabled = true
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func unwindFromSecondary(segue: UIStoryboardSegue) {
        
    }

}
