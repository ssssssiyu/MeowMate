//
//  Event+CoreDataProperties.swift
//  MeowMate
//
//  Created by Siyu Zhou on 2025-04-06.
//
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var reminderTypes: NSObject?
    @NSManaged public var cat: Cat?

}

extension Event : Identifiable {

}
