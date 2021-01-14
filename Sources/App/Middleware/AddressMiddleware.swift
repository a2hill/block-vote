//
//  AddressMiddleware.swift
//  
//
//  Created by Austin Hill on 1/10/21.
//

import Vapor

struct AddressMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            try AddressRequest.validate(query: request)
            return next.respond(to: request)
        } catch {
            return request.eventLoop.future(error: Abort(.badRequest))
        }
    }
}
