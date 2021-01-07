//
//  AdminMiddleware.swift
//  
//
//  Created by Austin Hill on 1/6/21.
//

import Vapor

struct AdminMiddleware: Middleware {
    
    let administrators: [String]
    
    init(administrators: [String]) {
        self.administrators = administrators
    }

   func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {

    guard let voteRequest = request.auth.get(VoteRequest.self), administrators.contains(voteRequest.id!) else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }

        return next.respond(to: request)
    }
}
