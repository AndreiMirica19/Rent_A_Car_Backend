//
//  File.swift
//  
//
//  Created by Andrei Mirica on 06.03.2023.
//

import Foundation
import Vapor
import Fluent

final class CarInfo: Model, Content {
    static let schema = "cars"
    
    @ID
    var id: UUID?
    
    @Field(key: "ownerId")
    var ownerId: String
    
    @Field(key: "numberPlate")
    var numberPlate: String
    
    @Field(key: "manufacturer")
    var manufacturer: String
    
    @Field(key: "model")
    var model: String
    
    @Field(key: "manufactureYear")
    var manufactureYear: String
    
    @Field(key: "transmission")
    var transmission: String
    
    @Field(key: "color")
    var color: String
    
    @Field(key: "fuel")
    var fuel: String
    
    @Field(key: "numberSeats")
    var numberSeats: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "street")
    var street: String
    
    @Field(key: "city")
    var city: String
    
    @Field(key: "country")
    var country: String
    
    @Field(key: "photos")
    var photos: [Data]
    
    @Field(key: "price")
    var price: String
    
    @Field(key: "currency")
    var currency: String
    
    @Field(key: "discount")
    var discount: Bool
}
