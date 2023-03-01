//
//  File.swift
//  
//
//  Created by Andrei Mirica on 01.03.2023.
//

import Foundation
import Vapor
import Fluent

struct Car: Content {
    let manufacturer: String
    let model: String
}
