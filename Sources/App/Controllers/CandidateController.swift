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
        return Candidate.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let voteRequest = try req.auth.require(VoteRequest.self)
        return try CanidateLogic.getCandidate(by: voteRequest.candidate, db: req.db)
            .guard({ $0 == nil }, else: Abort(.notModified, reason: "Candidate already exists"))
            .flatMap { _ in
                Candidate(name: voteRequest.candidate).save(on: req.db)
            }.transform(to: .created)
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let voteRequest = try req.auth.require(VoteRequest.self)
        let candidate = try CanidateLogic.getCandidate(by: voteRequest.candidate, db: req.db)
            .unwrap(or: Abort(.notFound, reason: "Candidate does not exist"))
        
        return candidate.flatMap {
            $0.delete(on: req.db)
        }.transform(to: .noContent)
    }
    
//    func getCandidate(req: Request) throws -> EventLoopFuture<Candidate?> {
//        let voteRequest = try req.auth.require(VoteRequest.self)
//        return Candidate.query(on: req..db).filter(\.$id == voteRequest.candidate).first()
//    }
}

struct CanidateLogic {
    static func getCandidate(by name: String, db: Database) throws -> EventLoopFuture<Candidate?> {
        let candidate =  Candidate.query(on: db)
            .filter(\.$id == name)
            .first()
        return candidate
    }
}
