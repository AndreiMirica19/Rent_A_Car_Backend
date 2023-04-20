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
    
    app.get("cars") { req -> EventLoopFuture<[Car]> in
        let carList = Helper().carList
        return req.eventLoop.makeSucceededFuture(carList)
    }
    
    app.post("addCar") { req -> EventLoopFuture<ApiResponse> in
        let carData = try req.content.decode(CarInfo.self)
        return carData.save(on: req.db).map {
            return ApiResponse(statusCode: 201, message: "Car Added")
        }.flatMapError { error in
            if let error = error as? PostgresError {
                return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 400, message: error.getErrorMessage()))
            }
            return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 500, message: "Unexpected error occurred"))
        }
    }
    
    app.get("ownedCars") { req -> EventLoopFuture<[CarInfo]> in
        guard let id = req.query[String.self, at: "owner_id"] else {
            throw Abort(.badRequest)
        }
        
        return CarInfo.query(on: req.db)
            .filter(\.$ownerId == id)
            .all()
    }
    
    app.get("hostInfo") { req -> EventLoopFuture<HostInfo> in
        guard let id = req.query[String.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        let userQuery = UserDetails.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .unwrap(or: Abort(.notFound))
        
        let carQuery = CarInfo.query(on: req.db)
            .filter(\.$ownerId == id)
            .all()
        
        return userQuery.and(carQuery).flatMap { (user, cars) in
            req.eventLoop.makeSucceededFuture(HostInfo(hostDetails: user, ownedCars: cars, reviews: []))
        }
    }
    
    app.get("allCars") { req -> EventLoopFuture<[CarInfo]> in
        
        return CarInfo.query(on: req.db)
            .all()
    }
    
    app.put("toggleFavoriteCar") { req -> EventLoopFuture<[CarInfo]> in
        
        guard let id = req.query[String.self, at: "id"], let carId = req.query[String.self, at: "carId"] else {
            throw Abort(.badRequest)
        }
        
        
        guard let userUuid = UUID(id) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid uuid format"))
        }
        
        
        return UserDetails.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { userDetails in
                if userDetails.favoriteCars.firstIndex(of: carId) != nil {
                    userDetails.favoriteCars.removeAll(where: { $0 == carId })
                } else {
                    userDetails.favoriteCars.append(carId)
                }
                return userDetails.save(on: req.db).flatMap{
                    
                    let favoriteCarIds = userDetails.favoriteCars.compactMap { UUID(uuidString: $0) }
                    return CarInfo.query(on: req.db)
                        .filter(\.$id ~~ favoriteCarIds)
                        .all()
                }
            }
    }
    
    app.get("favoriteCars") { req -> EventLoopFuture<[CarInfo]> in
        guard let id = req.query[String.self, at: "id"],
              let userUuid = UUID(uuidString: id)
        else {
            throw Abort(.badRequest)
        }
        return UserDetails.query(on: req.db)
            .filter(\.$id == userUuid)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { userDetails in
                let favoriteCarIds = userDetails.favoriteCars.compactMap { UUID(uuidString: $0) }
                return CarInfo.query(on: req.db)
                    .filter(\.$id ~~ favoriteCarIds)
                    .all()
            }
    }
    
    app.post("bookCar") { req -> EventLoopFuture<ApiResponse> in
        print(req.content)
        let createBooking = try req.content.decode(Booking.AddBooking.self)
        
        return Booking.query(on: req.db)
            .first()
            .flatMap { existingUser in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                if let fromDate = dateFormatter.date(from: createBooking.fromDate), let toDate = dateFormatter.date(from: createBooking.toDate) {
                    let booking = Booking(ownerId: createBooking.ownerId,
                                          renterId: createBooking.renterId,
                                          carId: createBooking.carId,
                                          fromDate: fromDate,
                                          toDate: toDate,
                                          status: createBooking.status)
                    return booking.save(on: req.db).map {
                        return ApiResponse(statusCode: 201, message: "Booking created")
                    }
                } else {
                    return req.eventLoop.makeSucceededFuture(ApiResponse(statusCode: 400, message: "Wrong date format"))
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
    
    app.get("userBookings") { req -> EventLoopFuture<[BookingInfo]> in
        guard let id = req.query[String.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        
        let bookingsFuture = Booking.query(on: req.db)
            .filter(\.$renterId == id)
            .all()
        
        return bookingsFuture.flatMap { bookings -> EventLoopFuture<[BookingInfo]> in
            var bookingFutures: [EventLoopFuture<BookingInfo?>] = []
            
            for booking in bookings {
                guard let hostId = UUID(booking.ownerId), let renterId = UUID(booking.renterId), let carId = UUID(booking.carId) else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound))
                }
                
                let hostQuery = UserDetails.query(on: req.db)
                    .filter(\.$id == hostId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                
                hostQuery.whenFailure { error in
                    req.logger.error("Error in hostQuery: \(error)")
                }
                
                let hostCarsQuery = CarInfo.query(on: req.db)
                    .filter(\.$ownerId == booking.ownerId)
                    .all()
                
                hostCarsQuery.whenFailure { error in
                    req.logger.error("Error in hostCarsQuery: \(error)")
                }
                
                let renterQuery = UserDetails.query(on: req.db)
                    .filter(\.$id == renterId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                
                renterQuery.whenFailure { error in
                    req.logger.error("Error in renterQuery: \(error)")
                }
                
                let carInfoQuery = CarInfo.query(on: req.db)
                    .filter(\.$id == carId)
                    .first()
                
                carInfoQuery.whenFailure { error in
                    req.logger.error("Error in carInfoQuery: \(error)")
                }
                let bookingFuture: EventLoopFuture<BookingInfo?> = hostQuery.and(hostCarsQuery).and(renterQuery).and(carInfoQuery).flatMap { tuple in
                    let (((host, hostCars), renter), carInfo) = tuple
                    guard let carInfo = carInfo else {
                        return req.eventLoop.makeSucceededFuture(nil)
                    }
                    let hostDetails = HostInfo(hostDetails: host, ownedCars: hostCars, reviews: [])
                    let bookingInfo = BookingInfo(id: booking.id ?? UUID(),
                                                  hostInfo: hostDetails,
                                                  renterDetails: renter,
                                                  carInfo: carInfo,
                                                  fromDate: booking.fromDate,
                                                  toDate: booking.toDate,
                                                  status: booking.status)
                    return req.eventLoop.makeSucceededFuture(bookingInfo)
                }
                
                bookingFutures.append(bookingFuture)
                
                bookingFuture.whenSuccess { bookingInfo in
                    if let bookingInfo = bookingInfo {
                        req.logger.info("Booking Info: \(bookingInfo)")
                    } else {
                        req.logger.info("Booking Info is nil")
                    }
                }
                
                bookingFuture.whenFailure { error in
                    req.logger.error("Error in bookingFuture: \(error)")
                }
            }
            
            let allBookingsFuture = EventLoopFuture.whenAllComplete(bookingFutures, on: req.eventLoop)
            
            return allBookingsFuture.flatMap { results in
                let bookings = results.compactMap { result -> BookingInfo? in
                    if case .success(let booking) = result {
                        return booking
                    } else {
                        return nil
                    }
                }
                return req.eventLoop.makeSucceededFuture(bookings)
            }.flatMapError { error in
                req.logger.error("Error in allBookingsFuture: \(error)")
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
            }
        }
    }
    
    app.get("hostBookings") { req -> EventLoopFuture<[BookingInfo]> in
        guard let id = req.query[String.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        
        let bookingsFuture = Booking.query(on: req.db)
            .filter(\.$ownerId == id)
            .all()
        
        return bookingsFuture.flatMap { bookings -> EventLoopFuture<[BookingInfo]> in
            var bookingFutures: [EventLoopFuture<BookingInfo?>] = []
            
            for booking in bookings {
                guard let hostId = UUID(booking.ownerId), let renterId = UUID(booking.renterId), let carId = UUID(booking.carId) else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound))
                }
                
                let hostQuery = UserDetails.query(on: req.db)
                    .filter(\.$id == hostId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                
                hostQuery.whenFailure { error in
                    req.logger.error("Error in hostQuery: \(error)")
                }
                
                let hostCarsQuery = CarInfo.query(on: req.db)
                    .filter(\.$ownerId == booking.ownerId)
                    .all()
                
                hostCarsQuery.whenFailure { error in
                    req.logger.error("Error in hostCarsQuery: \(error)")
                }
                
                let renterQuery = UserDetails.query(on: req.db)
                    .filter(\.$id == renterId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                
                renterQuery.whenFailure { error in
                    req.logger.error("Error in renterQuery: \(error)")
                }
                
                let carInfoQuery = CarInfo.query(on: req.db)
                    .filter(\.$id == carId)
                    .first()
                
                carInfoQuery.whenFailure { error in
                    req.logger.error("Error in carInfoQuery: \(error)")
                }
                let bookingFuture: EventLoopFuture<BookingInfo?> = hostQuery.and(hostCarsQuery).and(renterQuery).and(carInfoQuery).flatMap { tuple in
                    let (((host, hostCars), renter), carInfo) = tuple
                    guard let carInfo = carInfo else {
                        return req.eventLoop.makeSucceededFuture(nil)
                    }
                    let hostDetails = HostInfo(hostDetails: host, ownedCars: hostCars, reviews: [])
                    let bookingInfo = BookingInfo(id: booking.id ?? UUID(),
                                                  hostInfo: hostDetails,
                                                  renterDetails: renter,
                                                  carInfo: carInfo,
                                                  fromDate: booking.fromDate,
                                                  toDate: booking.toDate,
                                                  status: booking.status)
                    return req.eventLoop.makeSucceededFuture(bookingInfo)
                }
                
                bookingFutures.append(bookingFuture)
                
                bookingFuture.whenSuccess { bookingInfo in
                    if let bookingInfo = bookingInfo {
                        req.logger.info("Booking Info: \(bookingInfo)")
                    } else {
                        req.logger.info("Booking Info is nil")
                    }
                }
                
                bookingFuture.whenFailure { error in
                    req.logger.error("Error in bookingFuture: \(error)")
                }
            }
            
            let allBookingsFuture = EventLoopFuture.whenAllComplete(bookingFutures, on: req.eventLoop)
            
            return allBookingsFuture.flatMap { results in
                let bookings = results.compactMap { result -> BookingInfo? in
                    if case .success(let booking) = result {
                        return booking
                    } else {
                        return nil
                    }
                }
                return req.eventLoop.makeSucceededFuture(bookings)
            }.flatMapError { error in
                req.logger.error("Error in allBookingsFuture: \(error)")
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
            }
        }
    }
    
    app.put("updateStatus") { req -> EventLoopFuture<ApiResponse> in
        guard let id = req.query[String.self, at: "id"], let status = req.query[String.self, at: "status"], let bookingUUID = UUID(uuidString: id) else {
            throw Abort(.badRequest)
        }
        
        let bookingsFuture = Booking.query(on: req.db)
            .filter(\.$id == bookingUUID)
            .first()
        
        return bookingsFuture.flatMap { booking -> EventLoopFuture<ApiResponse> in
            guard let booking = booking else {
                let response = ApiResponse( statusCode: 404, message: "Booking not found")
                return req.eventLoop.makeSucceededFuture(response)
            }
            
            booking.status = status
            
            return booking.save(on: req.db).transform(to: ApiResponse(statusCode: 200, message: "Booking updated successfully"))
        }
    }
    
    app.get("hostStats") { req -> EventLoopFuture<HostStats> in
        guard let id = req.query[String.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        
        let bookingsFuture = Booking.query(on: req.db)
            .filter(\.$ownerId == id)
            .all()
        
        return bookingsFuture.flatMap { bookings -> EventLoopFuture<HostStats> in
            var bookingFutures: [EventLoopFuture<BookingInfo?>] = []
            
            for booking in bookings {
                guard let hostId = UUID(booking.ownerId), let renterId = UUID(booking.renterId), let carId = UUID(booking.carId) else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound))
                }
                
                let hostQuery = UserDetails.query(on: req.db)
                    .filter(\.$id == hostId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                
                hostQuery.whenFailure { error in
                    req.logger.error("Error in hostQuery: \(error)")
                }
                
                let hostCarsQuery = CarInfo.query(on: req.db)
                    .filter(\.$ownerId == booking.ownerId)
                    .all()
                
                hostCarsQuery.whenFailure { error in
                    req.logger.error("Error in hostCarsQuery: \(error)")
                }
                
                let renterQuery = UserDetails.query(on: req.db)
                    .filter(\.$id == renterId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                
                renterQuery.whenFailure { error in
                    req.logger.error("Error in renterQuery: \(error)")
                }
                
                let carInfoQuery = CarInfo.query(on: req.db)
                    .filter(\.$id == carId)
                    .first()
                
                carInfoQuery.whenFailure { error in
                    req.logger.error("Error in carInfoQuery: \(error)")
                }
                let bookingFuture: EventLoopFuture<BookingInfo?> = hostQuery.and(hostCarsQuery).and(renterQuery).and(carInfoQuery).flatMap { tuple in
                    let (((host, hostCars), renter), carInfo) = tuple
                    guard let carInfo = carInfo else {
                        return req.eventLoop.makeSucceededFuture(nil)
                    }
                    let hostDetails = HostInfo(hostDetails: host, ownedCars: hostCars, reviews: [])
                    let bookingInfo = BookingInfo(id: booking.id ?? UUID(),
                                                  hostInfo: hostDetails,
                                                  renterDetails: renter,
                                                  carInfo: carInfo,
                                                  fromDate: booking.fromDate,
                                                  toDate: booking.toDate,
                                                  status: booking.status)
                    return req.eventLoop.makeSucceededFuture(bookingInfo)
                }
                
                bookingFutures.append(bookingFuture)
                
                bookingFuture.whenSuccess { bookingInfo in
                    if let bookingInfo = bookingInfo {
                        req.logger.info("Booking Info: \(bookingInfo)")
                    } else {
                        req.logger.info("Booking Info is nil")
                    }
                }
                
                bookingFuture.whenFailure { error in
                    req.logger.error("Error in bookingFuture: \(error)")
                }
            }
            
            let allBookingsFuture = EventLoopFuture.whenAllComplete(bookingFutures, on: req.eventLoop)
            
            return allBookingsFuture.flatMap { results in
                let bookings = results.compactMap { result -> BookingInfo? in
                    if case .success(let booking) = result {
                        return booking
                    } else {
                        return nil
                    }
                }
                return req.eventLoop.makeSucceededFuture(Helper.getHostStats(bookings: bookings))
            }.flatMapError { error in
                req.logger.error("Error in allBookingsFuture: \(error)")
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
            }
        }
    }
    
}


