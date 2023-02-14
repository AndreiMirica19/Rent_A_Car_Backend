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
    
    
    app.post("login") { req -> EventLoopFuture<User> in
        let credentials = try req.content.decode(Credentials.self)
        
        return User.query(on: req.db)
            .filter(\.$email == credentials.email)
            .filter(\.$password == credentials.password)
            .first()
            .unwrap(or: Abort(.unauthorized, reason: "Invalid email or password"))
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
    
    app.get("userDetails", ":id") { req -> EventLoopFuture<UserDetails> in
        
        guard let id = req.parameters.get("id") else {
            print(req.parameters)
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "An ID is requiered"))
            
        }
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        
        return UserDetails.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .unwrap(or: Abort(.notFound, reason: "Account not found"))
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
    
}

