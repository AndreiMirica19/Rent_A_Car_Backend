//
//  File.swift
//  
//
//  Created by Andrei Mirica on 15.01.2023.
//

import Vapor
import Fluent

struct Credentials: Content {
    var email: String
    var password: String
}
