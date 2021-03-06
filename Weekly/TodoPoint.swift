//
//  TodoPoint.swift
//  
//
//  Created by YunSeungyong on 2015. 8. 1..
//
//

import Foundation
import CoreData

class TodoPoint: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    // Insert code here to add functionality to your managed object subclass
    class func createInManagedObjectContext(moc: NSManagedObjectContext, title: String, note: String, year: Int,weekOfYear: Int, weekDay: Int,  priority: Int, type: Int) -> TodoPoint {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("TodoPoint", inManagedObjectContext: moc) as! TodoPoint
        newItem.title = title
        newItem.note = note
        newItem.year = year
        newItem.weekDay = weekDay
        newItem.weekOfYear = weekOfYear
        newItem.priority = priority
        newItem.type = type
        newItem.state = 0
        
        return newItem
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        self.createdAt = NSDate();
    }
    
    func changeState(state: NSNumber) {
        self.state = state
    }

}
