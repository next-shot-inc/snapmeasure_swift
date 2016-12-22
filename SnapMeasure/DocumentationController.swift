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
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    fileprivate func makeController(_ page: String) -> UIViewController {
         let ctrler = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DocumentationWebPage")
         let docCtrler = ctrler as! DocumentationWebViewController
         docCtrler.doc = page
         return docCtrler
    }
    
    fileprivate(set) lazy var orderViewControllers : [UIViewController] = {
        return [
            self.makeController("doc1"),
            self.makeController("doc2")
        ]
    }()
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let viewControllerIndex = orderViewControllers.index(of: viewController)
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
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let viewControllerIndex = orderViewControllers.index(of: viewController)
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
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let firstViewController = orderViewControllers.first
        return orderViewControllers.index(of: firstViewController!)!
    }
    
}

class DocumentationWebViewController : UIViewController {
    var doc = String()
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        let localfilePath = Bundle.main.url(forResource: "help/" + doc, withExtension: "html");
        let myRequest = URLRequest(url: localfilePath!)
        webView.loadRequest(myRequest)
    }
}
