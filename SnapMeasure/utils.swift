//
//  utils.swift
//  SnapMeasure
//
//  Created by next-shot on 7/1/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit

class Utility {
    // Display Angle with a direction name and a degree symbol.
    static func formatAngle(angle: Double, orient: Bool) -> NSAttributedString {
        let nf = NSNumberFormatter()
        let number = nf.stringFromNumber(angle)
        var string = number! + "o "
        if( orient ) {
            string += {
                let definedHeadingsNames = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
                let quad = 360/definedHeadingsNames.count
                for( var i=0; i < definedHeadingsNames.count; ++i) {
                    let dir = i * quad
                    var vmin = dir - quad/2
                    let vmax = dir + quad/2
                    if( vmin < 0 ) {
                        vmin = 360-quad/2
                        if( Int(angle) >= vmin || Int(angle) < vmax ) {
                            return definedHeadingsNames[i]
                        }
                    } else {
                        if( Int(angle) >= vmin && Int(angle) < vmax ) {
                            return definedHeadingsNames[i]
                        }
                    }
                }
                return " "
            }()
        }
        
        let astring = NSMutableAttributedString(
            string: string,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(20.0)]
        )
        
        let range = (string as NSString).rangeOfString("o")
        let superAttributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(10.0),
            NSBaselineOffsetAttributeName: 10.0
        ]
        astring.addAttributes(superAttributes, range: range)
        return astring
    }
}
