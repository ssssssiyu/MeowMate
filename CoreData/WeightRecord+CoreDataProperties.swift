//
//  WeightRecord+CoreDataProperties.swift
//  MeowMate
//
//  Created by Siyu Zhou on 2025-04-06.
//
//

import Foundation
import CoreData


extension WeightRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeightRecord> {
        return NSFetchRequest<WeightRecord>(entityName: "WeightRecord")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var weight: Double
    @NSManaged public var cat: Cat?

}

extension WeightRecord : Identifiable {

}
