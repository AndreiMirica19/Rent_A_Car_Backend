//
//  File.swift
//  
//
//  Created by Andrei Mirica on 10.04.2023.
//

import Foundation
import Vapor

struct BookingInfo: Content {
    let id: UUID
    let hostInfo: HostInfo
    let renterDetails: UserDetails
    let carInfo: CarInfo
    let fromDate: Date
    let toDate: Date
    let status: String
}

