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
        
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        if orientation == UIInterfaceOrientation.Portrait || orientation == UIInterfaceOrientation.PortraitUpsideDown {
            self.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay
        }
        
    }
    
    override func viewWillTransitionToSize(size: CGSize,
        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            // willRotateToInterfaceOrientation code goes here
            coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
                // willAnimateRotationToInterfaceOrientation code goes here
                super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
                
                }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    // didRotateFromInterfaceOrientation goes here
                    self.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic
            })
    }
    
    override func unwindForSegue(unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        if( unwindSegue.identifier == "unwindFromHistogramToMain" ) {
        }
    }
}