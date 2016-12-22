//
//  HistogramSplitViewController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/22/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit

class HistogramSplitViewController : UISplitViewController {
    var detailedHistogramController : HistogramDetailViewController?
    var masterHistogramController : HistogramMasterViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftNavController = self.viewControllers.first as! UINavigationController
        let masterVC = leftNavController.topViewController as! HistogramMasterViewController
        
        let rightNavContoller = self.viewControllers.last as! UINavigationController
        let detailVC = rightNavContoller.topViewController as! HistogramDetailViewController
        
        masterVC.delegate = detailVC
        masterHistogramController = masterVC
        detailedHistogramController = detailVC
        
        let orientation = UIApplication.shared.statusBarOrientation
        if orientation == UIInterfaceOrientation.portrait || orientation == UIInterfaceOrientation.portraitUpsideDown {
            self.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryOverlay
        }
        
    }
    
    override func viewWillTransition(to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator) {
            // willRotateToInterfaceOrientation code goes here
            coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                // willAnimateRotationToInterfaceOrientation code goes here
                super.viewWillTransition(to: size, with: coordinator)
                
                }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    // didRotateFromInterfaceOrientation goes here
                    self.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic
            })
    }
    
    override func unwind(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        if( unwindSegue.identifier == "unwindFromHistogramToMain" ) {
        }
    }
}
