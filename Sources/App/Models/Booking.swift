//
//  File.swift
//  
//
//  Created by Andrei Mirica on 09.04.2023.
//

import Foundation
import Vapor
import Fluent

final class Booking: Model, Content {

    static let schema = "bookings"
    
    @ID
    var id: UUID?
    
    @Field(key: "ownerId")
    var ownerId: String
    
    @Field(key: "renterId")
    var renterId: String
    
    @Field(key: "carId")
    var carId: String
    
    @Field(key: "fromDate")
    var fromDate: Date
    
    @Field(key: "toDate")
    var toDate: Date
    
    @Field(key: "status")
    var status: String
    
    init() {
        
    }
    
    init(id: UUID? = nil, ownerId: String, renterId: String, carId: String, fromDate: Date, toDate: Date, status: String) {
        self.id = id
        self.ownerId = ownerId
        self.renterId = renterId
        self.carId = carId
        self.fromDate = fromDate
        self.toDate = toDate
        self.status = status
    }
}

extension Booking {
    struct AddBooking: Content, Decodable {
        var fromDate: String
        var toDate: String
        var ownerId: String
        var renterId: String
        var carId: String
        var status: String
    }
}
