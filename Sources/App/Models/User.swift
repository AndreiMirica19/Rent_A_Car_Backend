//
//  File.swift
//  
//
//  Created by Andrei Mirica on 15.01.2023.
//

import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "phone")
    var phone: String
    
    @Field(key: "password")
    var password: String
    
    init() {
        
    }
    
    init(id: UUID? = nil, name: String, email: String, phone: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.password = passwordHash
    }
}

extension User {
    struct CreateUser: Content, Decodable {
        var name: String
        var email: String
        var phoneNumber: String
        var password: String
    }
}
