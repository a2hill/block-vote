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
        let candidates = routes.grouped("candidates")
        
        // Get
        candidates.get(use: listAllCandidates)
        
        // Admin required
        candidates.group([
            CandidateMiddleware(),
            SignatureAuthenticator<CandidateRequest>(),
            CandidateRequest.guardMiddleware(throwing:
                Abort(.unauthorized, reason: "Address, message, and signature do not match")
            ),
            AdminMiddleware<CandidateRequest>(administrators: ["1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"])]) { protected in
            protected.post(use: create)
            protected.delete(use: delete)
        }
    }
    
    func listAllCandidates(req: Request) throws -> EventLoopFuture<Page<Candidate>> {
        return Candidate.query(on: req.db).paginate(for: req)
    }

    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let voteRequest = try req.auth.require(CandidateRequest.self)
        return try CanidateLogic.getCandidate(by: voteRequest.candidate, db: req.db)
            .guard({ $0 == nil }, else: Abort(.notModified, reason: "Candidate already exists"))
            .flatMap { _ in
                Candidate(name: voteRequest.candidate).save(on: req.db)
            }.transform(to: .created)
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let voteRequest = try req.auth.require(CandidateRequest.self)
        let candidate = try CanidateLogic.getCandidate(by: voteRequest.candidate, db: req.db)
            .unwrap(or: Abort(.notFound, reason: "Candidate does not exist"))
        
        return candidate.flatMap {
            $0.delete(on: req.db)
        }.transform(to: .noContent)
    }
}

struct CanidateLogic {
    static func getCandidate(by name: String, db: Database) throws -> EventLoopFuture<Candidate?> {
        let candidate =  Candidate.query(on: db)
            .filter(\.$id == name)
            .first()
        return candidate
    }
}
