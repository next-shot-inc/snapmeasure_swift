//
//  FaciesImageObject.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/18/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData

class FaciesImageObject: NSManagedObject {
    
    @NSManaged var imageData: Data
    @NSManaged var name: String
    @NSManaged var tilePixmap: NSNumber
    
}

