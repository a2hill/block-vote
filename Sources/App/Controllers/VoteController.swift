//
//  File.swift
//  
//
//  Created by Hill, Austin on 11/28/20.
//

import Vapor

struct VoteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let vote = routes
            .grouped("votes")
            .grouped(VoteMiddleware())
        
        vote.get(use: index)
        vote.group([SignatureAuthenticator(), VoteRequest.guardMiddleware(throwing: Abort(.unauthorized, reason: "Address, message, and signature do not match"))]) { protected in
            protected.post(use: create)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[Vote]> {
        return Vote.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Vote> {
        
        let voteRequest = try req.auth.require(VoteRequest.self)
        let countedVote = req.blockchain.getBalance(address: voteRequest.id!)
            .map { balance -> Vote in
                return Vote(voteRequest, quantity: balance)
            }
            .flatMap { vote in
                return vote.save(on: req.db).map { vote }
            }
        
        return countedVote
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Candidate.find(req.parameters.get("todoID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
