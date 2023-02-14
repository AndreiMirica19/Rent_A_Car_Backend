//
//  File.swift
//  
//
//  Created by Andrei Mirica on 15.01.2023.
//

import Fluent
import Vapor

struct CreateUser: AsyncMigration {
    var name: String { "CreateUser" }
    
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("phone", .string, .required)
            .field("password", .string, .required)
            .unique(on: "email")
            .unique(on: "phone")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
