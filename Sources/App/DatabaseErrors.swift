//
//  File.swift
//  
//
//  Created by Andrei Mirica on 16.01.2023.
//

import Foundation
import PostgresNIO

extension PostgresError {
    
    func getErrorMessage() -> String {
        switch self.code {
        case "23505":
            return "Already used email/phone"
        default:
            return "unexpected error"
        }
    }
}
