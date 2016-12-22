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
    static func formatAngle(_ angle: Double, orient: Bool) -> NSAttributedString {
        let nf = NumberFormatter()
        let number = nf.string(from: NSNumber(value: angle))
        var string = number! + "o "
        if( orient ) {
            string += {
                let definedHeadingsNames = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
                let quad = 360/definedHeadingsNames.count
                for i in 0 ..< definedHeadingsNames.count {
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
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 20.0)]
        )
        
        let range = (string as NSString).range(of: "o")
        let superAttributes = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 10.0),
            NSBaselineOffsetAttributeName: 10.0
        ] as [String : Any]
        astring.addAttributes(superAttributes, range: range)
        return astring
    }
}
