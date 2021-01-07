//
//  VoteMiddleware.swift
//  
//
//  Created by Austin Hill on 1/7/21.
//

import Vapor

struct VoteMiddleware: Middleware {

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            try VoteRequest.validate(content: request)
            return next.respond(to: request)
        } catch {
            return request.eventLoop.future(error: Abort(.badRequest))
        }
    }
}
