//
//  File.swift
//  
//
//  Created by Andrei Mirica on 16.01.2023.
//

import Fluent
import Vapor

struct ApiResponse: Content, Error {
    let statusCode: Int?
    let message: String?
}
