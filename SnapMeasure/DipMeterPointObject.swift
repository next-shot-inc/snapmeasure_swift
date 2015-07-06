//
//  DipMeterPointObject.swift
//  SnapMeasure
//
//  Created by next-shot on 7/6/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData

class DipMeterPointObject: NSManagedObject {

    @NSManaged var dip: NSNumber
    @NSManaged var locationInImage: AnyObject
    @NSManaged var realLocation: AnyObject
    @NSManaged var strike: NSNumber
    @NSManaged var feature: String

}
