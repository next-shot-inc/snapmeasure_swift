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
    @NSManaged var gpsLocation: String
    @NSManaged var lines: NSSet
    @NSManaged var features: NSSet

}
