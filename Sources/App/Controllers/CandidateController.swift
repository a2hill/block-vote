//
//  File.swift
//  
//
//  Created by Austin Hill on 1/5/21.
//

import Fluent
import Vapor

struct CandidateController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let candidates = routes
            .grouped("candidates")
            .grouped(VoteMiddleware())
        
        candidates.get(use: index)
        candidates.group([SignatureAuthenticator(), AdminMiddleware(administrators: ["1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"])]) { protected in
            protected.post(use: create)
        }
//        candidates.group(":id") { todo in
//            todo.delete(use: delete)
//        }
    }
    
    func index(req: Request) throws -> EventLoopFuture<[Candidate]> {
        let candidates = Candidate.query(on: req.db)
            .all(\.$name)
            .mapEach { candidateName in
                Candidate(name: candidateName)
            }
        
        return candidates
    }

    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let voteRequest = try req.auth.require(VoteRequest.self)
        
        return Candidate.query(on: req.db)
            .filter(\.$name == voteRequest.candidate)
            .first()
            .guard({
                $0 == nil
            }, else: Abort(.notModified, reason: "Candidate already exists"))
            .flatMap { _ in
                Candidate(name: voteRequest.candidate).save(on: req.db)}
            .transform(to: .created)
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Todo.find(req.parameters.get("candidateID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
