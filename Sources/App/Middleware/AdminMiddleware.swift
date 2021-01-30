//
//  AdminMiddleware.swift
//  
//
//  Created by Austin Hill on 1/6/21.
//

import Vapor

struct AdminMiddleware<T: SignedRequest>: Middleware {
    typealias RequestType = T
    
    let administrators: [String]
    
    init(administrators: [String]) {
        self.administrators = administrators
    }

   func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let signedRequest = request.auth.get(RequestType.self), administrators.contains(signedRequest.id!) else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }

        return next.respond(to: request)
    }
}
