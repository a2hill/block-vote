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
        
        // Get
        candidates.get(use: index)
        
        // Admin required
        candidates.group([SignatureAuthenticator(), AdminMiddleware(administrators: ["1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"])]) { protected in
            protected.post(use: create)
            protected.delete(use: delete)
        }
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
        return try getCandidate(req: req)
            .guard({
                $0 == nil
            }, else: Abort(.notModified, reason: "Candidate already exists"))
            .flatMap { _ in
                Candidate(name: voteRequest.candidate).save(on: req.db)
            }.transform(to: .created)
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try getCandidate(req: req)
            .unwrap(or: Abort(.notFound, reason: "Candidate does not exist"))
            .flatMap { candidate in
                candidate.delete(on: req.db)
            }.transform(to: HTTPStatus.noContent)
    }
    
    func getCandidate(req: Request) throws -> EventLoopFuture<Candidate?> {
        let voteRequest = try req.auth.require(VoteRequest.self)
        let candidate =  Candidate.query(on: req.db)
            .filter(\.$name == voteRequest.candidate)
            .first()
        return candidate
    }
}
