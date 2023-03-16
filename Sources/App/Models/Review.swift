//
//  File.swift
//  
//
//  Created by Andrei Mirica on 16.03.2023.
//

import Foundation
import Vapor

struct Review: Content {
    var userProfilePicture: Date
    var userName: String
    var stars: Int
    var date: Date
}
