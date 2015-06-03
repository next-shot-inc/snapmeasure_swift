//
//  Feature.swift
//  SnapMeasure
//
//  Created by next-shot on 6/3/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData

class FeatureObject : NSManagedObject {

    @NSManaged var height: NSNumber
    @NSManaged var width: NSNumber
    @NSManaged var type: String
    @NSManaged var image: DetailedImageObject

}
