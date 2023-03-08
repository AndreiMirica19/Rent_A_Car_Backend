//
//  File.swift
//  
//
//  Created by Andrei Mirica on 06.03.2023.
//

import Foundation
import Fluent
import Vapor

struct AddCar: AsyncMigration {
    var name: String { "AddCar" }
    
    func prepare(on database: Database) async throws {
        try await database.schema("cars")
            .id()
            .field("ownerId", .string, .required)
            .field("numberPlate", .string, .required)
            .field("manufacturer", .string, .required)
            .field("model", .string, .required)
            .field("manufactureYear", .string, .required)
            .field("transmission", .string, .required)
            .field("color", .string, .required)
            .field("fuel", .string, .required)
            .field("description", .string, .required)
            .field("numberSeats", .string, .required)
            .field("street", .string, .required)
            .field("city", .string, .required)
            .field("country", .string, .required)
            .field("photos", .array(of: .data), .required)
            .field("price", .string, .required)
            .field("currency", .string, .required)
            .field("discount", .bool, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("cars").delete()
    }
}
