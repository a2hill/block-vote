//
//  File.swift
//  
//
//  Created by Austin Hill on 1/29/21.
//

import Vapor

struct CandidateMiddleware: Middleware {

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            try CandidateRequest.validate(content: request)
            return next.respond(to: request)
        } catch {
            return request.eventLoop.future(error: Abort(.badRequest))
        }
    }
}
