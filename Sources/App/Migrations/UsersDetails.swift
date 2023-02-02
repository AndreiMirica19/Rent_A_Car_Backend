//
//  File.swift
//  
//
//  Created by Andrei Mirica on 02.02.2023.
//

import Fluent
import Vapor

struct UsersDetails: AsyncMigration {
    var name: String { "UserDetails" }
    
    func prepare(on database: Database) async throws {
           try await database.schema("user_details")
               .id()
               .field("name", .string, .required)
               .field("about", .string, .required)
               .field("country", .string, .required)
               .field("city", .string, .required)
               .field("job", .string, .required)
               .field("profileImage", .data, .required)
               .field("spokenLanguages", .array(of: .string), .required)
               .create()
       }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_details").delete()
    }
}
