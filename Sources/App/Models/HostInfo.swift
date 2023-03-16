//
//  File.swift
//  
//
//  Created by Andrei Mirica on 16.03.2023.
//

import Foundation
import Vapor

struct HostInfo: Content {
    let hostDetails: UserDetails
    let ownedCars: [CarInfo]
    let reviews: [Review]
}
