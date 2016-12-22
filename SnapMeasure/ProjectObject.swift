//
//  ProjectObject.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 7/1/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData

class ProjectObject : NSManagedObject {
    
    @NSManaged var date : Date
    @NSManaged var name : String
    @NSManaged var detailedImages : NSSet
    
}
