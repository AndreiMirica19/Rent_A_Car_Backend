//
//  File.swift
//  
//
//  Created by Andrei Mirica on 19.04.2023.
//

import Foundation
import Vapor

struct HostStats: Content {
    let totalEarnings: Int
    let completedBookings: Int
    let numberOfReviews: Int
    let numberOfStars: Int
    let mostBookedCar: CarInfo?
}
