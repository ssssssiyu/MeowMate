//
//  Cat+CoreDataProperties.swift
//  MeowMate
//
//  Created by Siyu Zhou on 2025-04-06.
//
//

import Foundation
import CoreData


extension Cat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cat> {
        return NSFetchRequest<Cat>(entityName: "Cat")
    }

    @NSManaged public var birthDate: Date?
    @NSManaged public var breed: String?
    @NSManaged public var gender: String?
    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var isNeutered: Bool
    @NSManaged public var name: String?
    @NSManaged public var events: NSSet?
    @NSManaged public var weightRecords: NSSet?

}

// MARK: Generated accessors for events
extension Cat {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}

// MARK: Generated accessors for weightRecords
extension Cat {

    @objc(addWeightRecordsObject:)
    @NSManaged public func addToWeightRecords(_ value: WeightRecord)

    @objc(removeWeightRecordsObject:)
    @NSManaged public func removeFromWeightRecords(_ value: WeightRecord)

    @objc(addWeightRecords:)
    @NSManaged public func addToWeightRecords(_ values: NSSet)

    @objc(removeWeightRecords:)
    @NSManaged public func removeFromWeightRecords(_ values: NSSet)

}

extension Cat : Identifiable {

}
