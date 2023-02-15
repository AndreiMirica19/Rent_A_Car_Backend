import Fluent
import Vapor
import PostgresNIO

func routes(_ app: Application) throws {
    
    app.routes.defaultMaxBodySize = "100mb"
    
    app.post("register") { req -> EventLoopFuture<ApiResponse> in
        let create = try req.content.decode(User.CreateUser.self)
        return User.query(on: req.db)
            .filter(\.$email == create.email)
            .first()
            .flatMap { existingUser in
                let user = User(
                    name: create.name,
                    email: create.email,
                    phone: create.phoneNumber,
                    passwordHash: create.password
                )
                return user.save(on: req.db).map {
                    return ApiResponse(statusCode: 201, message: "User created")
                }
            }.flatMapError { error in
                if let error = error as? Abort {
                    return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 400, message: error.reason))
                } else {
                    if let error = error as? PostgresError {
                        return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 400, message: error.getErrorMessage()))
                    }
                    return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 500, message: "Unexpected error occurred"))
                }
            }
    }
    
    
    app.post("login") { req -> EventLoopFuture<Response> in
        let credentials = try req.content.decode(Credentials.self)
        
        return User.query(on: req.db)
            .filter(\.$email == credentials.email)
            .filter(\.$password == credentials.password)
            .first()
            .flatMap { user -> EventLoopFuture<Response> in
                if let user = user {
                    let response = Response(
                        status: .ok,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(user)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        let apiResponse = ApiResponse(statusCode: 500, message: "Failed to encode user details")
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: apiResponse.message))
                    }
                } else {
                    let apiResponse = ApiResponse(statusCode: 404, message: "User not found")
                    let response = Response(
                        status: .notFound,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(apiResponse)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to encode API response"))
                    }
                }
            }
            .flatMapError { error in
                if let error = error as? PostgresError {
                    let apiResponse = ApiResponse(statusCode: 400, message: error.getErrorMessage())
                    let response = Response(
                        status: .badRequest,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(apiResponse)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to encode API response"))
                    }
                } else {
                    let apiResponse = ApiResponse(statusCode: 500, message: "Unexpected error occurred")
                    let response = Response(
                        status: .internalServerError,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(apiResponse)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to encode API response"))
                    }
                }
                
            } 
    }
    
    app.post("editUserDetails") { req -> EventLoopFuture<UserDetails> in
        let create = try req.content.decode(UserDetails.self)
        
        guard let id = create.id else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "UserDetails must have an id"))
        }
        
        return UserDetails.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .flatMap { existingUserDetails in
                if let existingUserDetails = existingUserDetails {
                    existingUserDetails.name = create.name
                    existingUserDetails.about = create.about
                    existingUserDetails.country = create.country
                    existingUserDetails.city = create.city
                    existingUserDetails.job = create.job
                    existingUserDetails.profileImage = create.profileImage
                    existingUserDetails.spokenLanguages = create.spokenLanguages
                    return existingUserDetails.save(on: req.db).map {
                        return existingUserDetails
                    }
                } else {
                    return create.save(on: req.db).map {
                        return create
                    }
                }
            }
    }
    
    app.get("userDetails", ":id") { req -> EventLoopFuture<Response> in
        guard let id = req.parameters.get("id") else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "An ID is required"))
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        return UserDetails.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .flatMap { userDetails -> EventLoopFuture<Response> in
                if let userDetails = userDetails {
                    let response = Response(
                        status: .ok,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(userDetails)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        let apiResponse = ApiResponse(statusCode: 500, message: "Failed to encode user details")
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: apiResponse.message))
                    }
                } else {
                    let apiResponse = ApiResponse(statusCode: 404, message: "User not found")
                    let response = Response(
                        status: .notFound,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(apiResponse)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to encode API response"))
                    }
                }
            }
            .flatMapError { error in
                if let error = error as? PostgresError {
                    let apiResponse = ApiResponse(statusCode: 400, message: error.getErrorMessage())
                    let response = Response(
                        status: .badRequest,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(apiResponse)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to encode API response"))
                    }
                } else {
                    let apiResponse = ApiResponse(statusCode: 500, message: "Unexpected error occurred")
                    let response = Response(
                        status: .internalServerError,
                        version: HTTPVersion(major: 1, minor: 1),
                        headers: HTTPHeaders([("Content-Type", "application/json")])
                    )
                    do {
                        try response.content.encode(apiResponse)
                        return req.eventLoop.makeSucceededFuture(response)
                    } catch {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to encode API response"))
                    }
                }
            }
    }


    
    app.get("accountInfo", ":id") { req -> EventLoopFuture<User> in
        
        guard let id = req.parameters.get("id") else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "An ID is requiered"))
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        return User.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .unwrap(or: Abort(.notFound, reason: "Account not found"))
    }
    
    app.put("changeEmail") { req -> EventLoopFuture<ApiResponse> in
        guard let id = req.query[String.self, at: "id"], let newEmail = req.query[String.self, at: "email"] else {
            throw Abort(.badRequest)
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        return User.query(on: req.db)
            .filter(\.$email == newEmail)
            .first()
            .flatMap { existingUser in
                if existingUser != nil {
                    return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 409, message: "Email already in use"))
                } else {
                    return User.query(on: req.db)
                        .filter(\.$id == userUuid)
                        .first()
                        .flatMap { user in
                            if let user = user {
                                user.email = newEmail
                                return user.save(on: req.db).map {
                                    return ApiResponse(statusCode: 201, message: "Email updated")
                                }
                            } else {
                                return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 404, message: "Account not found"))
                            }
                        }
                }
            }
    }
    
    app.put("changePhoneNumber") { req -> EventLoopFuture<ApiResponse> in
        guard let id = req.query[String.self, at: "id"], let newPhoneNumber = req.query[String.self, at: "phone"] else {
            throw Abort(.badRequest)
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        return User.query(on: req.db)
            .filter(\.$phone == newPhoneNumber)
            .first()
            .flatMap { existingUser in
                if existingUser != nil {
                    return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 409, message: "Phone number already in use"))
                } else {
                    return User.query(on: req.db)
                        .filter(\.$id == userUuid)
                        .first()
                        .flatMap { user in
                            if let user = user {
                                user.phone = newPhoneNumber
                                return user.save(on: req.db).map {
                                    return ApiResponse(statusCode: 201, message: "Phone number updated")
                                }
                            } else {
                                return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 404, message: "Account not found"))
                            }
                        }
                }
            }
    }
    
    
    app.put("changePassword") { req -> EventLoopFuture<ApiResponse> in
        guard let id = req.query[String.self, at: "id"], let newPassword = req.query[String.self, at: "password"] else {
            throw Abort(.badRequest)
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        return User.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .flatMap { user in
                if let user = user {
                    user.password = newPassword
                    return user.save(on: req.db).map {
                        return ApiResponse(statusCode: 201, message: "Password updated")
                    }
                } else {
                    return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 404, message: "Account not found"))
                }
            }
    }
    
    app.delete("deleteAccount", ":id") { req -> EventLoopFuture<ApiResponse> in
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        let userDeleteFuture = User.query(on: req.db)
             .filter(\.$id == userUuid)
             .delete()

         let userDetailsDeleteFuture = UserDetails.query(on: req.db)
             .filter(\.$id == userUuid)
             .delete()

         return userDeleteFuture.and(userDetailsDeleteFuture)
             .transform(to: ApiResponse(statusCode: 200, message: "User account successfully deleted"))
    }
}


