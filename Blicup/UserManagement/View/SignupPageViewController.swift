//
//  SignupPageViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 09/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SignupPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var signupPresenter: SignupPresenter!
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        // The view controllers will be shown in this order
        return [self.newViewController("SignupUsernameVC"),
                self.newViewController("SignupPictureVC"),
                self.newViewController("SignupTermsPrivacyVC")]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disabled swipe change to prevent validantion problems
//        dataSource = self
//        delegate = self
        
        if let initialViewController = orderedViewControllers.first {
            setViewControllers([initialViewController], direction: .Forward, animated: true, completion: nil)
        }
    }
    

    private func newViewController(name: String) -> UIViewController {
        
        let viewController = UIStoryboard(name: "Signup", bundle: nil).instantiateViewControllerWithIdentifier(name)
        
        if let signupUsernameVC = viewController as? SignupUsernameViewController {
            signupUsernameVC.signupPresenter = self.signupPresenter
            self.signupPresenter.signupUsernameViewController = signupUsernameVC
        }
        else if let signupPictureVC = viewController as? SignupPictureViewController {
            signupPictureVC.signupPresenter = self.signupPresenter
            self.signupPresenter.signupPictureViewController = signupPictureVC
        }
        else if let signupTermsPrivacyVC = viewController as? SignupTermsPrivacyViewController {
            signupTermsPrivacyVC.signupPresenter = self.signupPresenter
            self.signupPresenter.signupTermsPrivacyViewController = signupTermsPrivacyVC
        }
        
        return viewController
    }

    func scrollToPageIndex(index:Int, isNext:Bool) {
        if index>=0 && index<orderedViewControllers.count  {
            let controller = orderedViewControllers[index]
            let direction: UIPageViewControllerNavigationDirection = isNext ? .Forward : .Reverse
            
            if #available(iOS 9.0, *) {
                self.setViewControllers([controller], direction: direction, animated: true, completion: nil)
            } else {
                self.setViewControllers([controller], direction: direction, animated: false, completion: nil)
            }
        
            self.signupPresenter.changedToPageIndex(index)
        }
    }
    
    
    func enableSwipePageChange(enable:Bool) {
        // There's no refresh on pageviewcontroller :(
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(pageViewController: UIPageViewController,
                            viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController,
                            viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        if self.signupPresenter.canGoToNextPage() {
            return orderedViewControllers[nextIndex]
        }
        else {
            return nil
        }
    }
    
    
    // MARK: UIPageViewControllerDelegate
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed {
            if let currentController = pageViewController.viewControllers!.first {
                if let index = orderedViewControllers.indexOf(currentController) {
                    self.signupPresenter.changedToPageIndex(index)
                }
            }
        }
    }
}

