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
        
        // Get
        vote.get(use: list)
        
        // Create
        vote.group([SignatureAuthenticator(), VoteRequest.guardMiddleware(throwing: Abort(.unauthorized, reason: "Address, message, and signature do not match"))]) { protected in
            protected.post(use: create)
        }
    }

    func list(req: Request) throws -> EventLoopFuture<[Vote]> {
        return Vote.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Vote> {
        
        let voteRequest = try req.auth.require(VoteRequest.self)
        
        let countedVote = req.blockchain.getBalance(address: voteRequest.id!)
            .and(Vote.find(voteRequest.id!, on: req.db))
            .flatMap { (balance: Double, existingVote: Vote?) -> EventLoopFuture<Vote> in
                // Vote already exists. Changing candidate.
                if let existingVote = existingVote {
                    existingVote.candidate = voteRequest.candidate
                    return existingVote.update(on: req.db).transform(to: existingVote)
                }else {
                    let newVote = Vote(voteRequest, quantity: balance)
                    return newVote.save(on: req.db).transform(to: newVote)
                }
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
