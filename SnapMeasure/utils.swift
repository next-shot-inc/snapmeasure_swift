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
    static func formatAngle(angle: Double, orient: Bool) -> NSAttributedString {
        var nf = NSNumberFormatter()
        let number = nf.stringFromNumber(angle)
        var string = number! + "o "
        if( orient ) {
            string += {
                let definedHeadingsNames = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
                var quad = 360/definedHeadingsNames.count
                for( var i=0; i < definedHeadingsNames.count; ++i) {
                    var dir = i * quad
                    var vmin = dir - quad/2
                    var vmax = dir + quad/2
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
        
        var astring = NSMutableAttributedString(
            string: string,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(20.0)]
        )
        
        var range = (string as NSString).rangeOfString("o")
        let superAttributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(10.0),
            NSBaselineOffsetAttributeName: 10.0
        ]
        astring.addAttributes(superAttributes, range: range)
        return astring
    }
}
