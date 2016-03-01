//
//  DocumentationController.swift
//  SnapMeasure
//
//  Created by next-shot on 2/29/16.
//  Copyright © 2016 next-shot. All rights reserved.
//

import UIKit

class DocumentationPageViewController : UIPageViewController, UIPageViewControllerDataSource {
    
    override func viewDidLoad() {
        dataSource = self
        
        if let firstViewController = orderViewControllers.first {
            setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    private func makeController(page: String) -> UIViewController {
         let ctrler = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("DocumentationWebPage")
         let docCtrler = ctrler as! DocumentationWebViewController
         docCtrler.doc = page
         return docCtrler
    }
    
    private(set) lazy var orderViewControllers : [UIViewController] = {
        return [
            self.makeController("doc1"),
            self.makeController("doc2")
        ]
    }()
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let viewControllerIndex = orderViewControllers.indexOf(viewController)
        if( viewControllerIndex == nil ) {
            return nil
        }
        let nextIndex = viewControllerIndex! + 1
        if( nextIndex < orderViewControllers.count ) {
            return orderViewControllers[nextIndex]
        } else {
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let viewControllerIndex = orderViewControllers.indexOf(viewController)
        if( viewControllerIndex == nil ) {
            return nil
        }
        let nextIndex = viewControllerIndex! - 1
        if( nextIndex > 0 ) {
            return orderViewControllers[nextIndex]
        } else {
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return orderViewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        let firstViewController = orderViewControllers.first
        return orderViewControllers.indexOf(firstViewController!)!
    }
    
}

class DocumentationWebViewController : UIViewController {
    var doc = String()
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        let localfilePath = NSBundle.mainBundle().URLForResource("help/" + doc, withExtension: "html");
        let myRequest = NSURLRequest(URL: localfilePath!)
        webView.loadRequest(myRequest)
    }
}
