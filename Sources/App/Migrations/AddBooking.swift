//
//  File.swift
//  
//
//  Created by Andrei Mirica on 10.04.2023.
//

import Foundation
import Fluent
import Vapor

struct AddBooking: AsyncMigration {
    var name: String { "AddBooking" }
    
    func prepare(on database: Database) async throws {
        try await database.schema("bookings")
            .id()
            .field("ownerId", .string, .required)
            .field("renterId", .string, .required)
            .field("carId", .string, .required)
            .field("fromDate", .datetime, .required)
            .field("toDate", .datetime, .required)
            .field("status", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("bookings").delete()
    }
}
