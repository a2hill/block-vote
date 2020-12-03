//
//  File.swift
//  
//
//  Created by Hill, Austin on 11/28/20.
//

import Fluent
import Vapor

struct VoteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let vote = routes.grouped("vote")
        vote.get(use: index)
        vote.post(use: create)
    }

    func index(req: Request) throws -> EventLoopFuture<[Vote]> {
        return Vote.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Vote> {
        let voteRequest = try req.content.decode(VoteRequest.self)
        let countedVote = req.blockchain.validateMessage(address: voteRequest.id!, signature: voteRequest.signature, message: voteRequest.candidate)
            .guard({$0 == true },
                   else: Abort(.badRequest, reason: "Signature does not validate for given message and address"))
            .flatMap { _ in
                return req.blockchain.getBalance(address: voteRequest.id!)
            }.map { balance -> Vote in
                return Vote(voteRequest, quantity: balance)
            }
//            .flatMap { vote in
//                return vote.save(on: req.db).map { vote }
//            }
        
        return countedVote
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Todo.find(req.parameters.get("todoID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
