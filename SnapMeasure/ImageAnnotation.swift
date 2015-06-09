//
//  ImageMapAnnotation.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/9/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class ImageAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let image : UIImage
    let compassOrientation: CLLocationDirection
    let name : String
    
    init(name: String, image: UIImage, coordinate: CLLocationCoordinate2D, compassOrientation: CLLocationDirection) {
        self.name = name
        self.image = image
        self.coordinate = coordinate
        self.compassOrientation = compassOrientation
    }
    
    var subtitle: String {
        return name
    }
}
