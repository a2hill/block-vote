//
//  ExcludedVotersMiddleware.swift
//  
//
//  Created by Austin Hill on 2/7/21.
//

import Vapor

struct ExcludedVotersMiddleware<T: SignedRequest>: Middleware {
    typealias RequestType = T
    
    let exludedVoters: [String]
    
    init(excludedVoters: [String]) {
        self.exludedVoters = excludedVoters
    }

   func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let signedRequest = request.auth.get(RequestType.self), !exludedVoters.contains(signedRequest.id!) else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Address has been excluded from this vote"))
        }

        return next.respond(to: request)
    }
}
