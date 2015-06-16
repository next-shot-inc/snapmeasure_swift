//
//  DetailedImage.swift
//  SnapMeasure
//
//  Created by next-shot on 6/3/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DetailedImageObject: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var imageData: NSData
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var altitude: NSNumber?
    @NSManaged var compassOrientation: NSNumber?
    @NSManaged var lines: NSSet
    @NSManaged var features: NSSet
    @NSManaged var date: NSDate
    @NSManaged var scale: NSNumber? // in meters per point
    @NSManaged var faciesVignettes: NSSet
    @NSManaged var texts : NSSet
}
