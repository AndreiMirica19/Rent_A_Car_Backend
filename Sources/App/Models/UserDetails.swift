//
//  File.swift
//  
//
//  Created by Andrei Mirica on 02.02.2023.
//
import Vapor
import Fluent

final class UserDetails: Model, Content {
    static let schema = "usersDetails"

    @ID
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "about")
    var about: String
    
    @Field(key: "country")
    var country: String
    
    @Field(key: "city")
    var city: String
    
    @Field(key: "job")
    var job: String
    
    @Field(key: "profileImage")
    var profileImage: Data
    
    @Field(key: "spokenLanguages")
    var spokenLanguages: [String]
}
