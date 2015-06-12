//
//  CustomCalloutView.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/12/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

enum CalloutAnimation : Int {
    case Bounce = 0, Fade = 1
}

enum CalloutArrowDirection : Int {
    case Down = 0, Up = 1, Any = 2
}

@objc protocol CustomCalloutViewDelegate {
    optional func calloutViewClicked(calloutView: CustomCalloutView)
    
    optional func calloutView(calloutView: CustomCalloutView, delayForRepositionWithSize offset: CGSize)
    
}

class CustomCalloutView: UIView {
    
}

class CalloutBackgroundView: UIView {
    var arrowPoint: CGPoint?
    var contentMask : CALayer?
    
}