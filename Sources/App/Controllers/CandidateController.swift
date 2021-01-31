//
//  File.swift
//  
//
//  Created by Austin Hill on 1/5/21.
//

import Fluent
import Vapor

struct CandidateController: RouteCollection {
    
    private let adminAuthenticator: AdminMiddleware<CandidateRequest>
    
    init(adminAuthenticator: AdminMiddleware<CandidateRequest>) {
        self.adminAuthenticator = adminAuthenticator
    }
    
    func boot(routes: RoutesBuilder) throws {
        let candidatesRoutes = routes.grouped("candidates")
        
        // Get
        candidatesRoutes.get(use: listAllCandidates)
        
        // Admin required
        let protectedRoutes = candidatesRoutes.grouped([
            CandidateMiddleware(),
            SignatureAuthenticator<CandidateRequest>(),
            CandidateRequest.guardMiddleware(throwing:
                Abort(.unauthorized, reason: "Address, message, and signature do not match")
            ),
            adminAuthenticator
        ])
        
        protectedRoutes.post(use: create)
        protectedRoutes.delete(use: delete)
    }
    
    func listAllCandidates(req: Request) throws -> EventLoopFuture<Page<Candidate>> {
        return Candidate.query(on: req.db).paginate(for: req)
    }

    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let candidateRequest = try req.auth.require(CandidateRequest.self)
        
        return try CanidateLogic.getCandidate(by: candidateRequest.candidate, db: req.db)
            .flatMap { (existingCandidate: Candidate?) in
                if let candidate = existingCandidate {
                    guard candidate.profileUrl != candidateRequest.profileUrl else {
                        return req.eventLoop.makeSucceededFuture(HTTPStatus.notModified)
                    }
                    if candidate.profileUrl != candidateRequest.profileUrl {
                        candidate.profileUrl = candidateRequest.profileUrl
                    }
                    return candidate.update(on: req.db)
                        .transform(to: HTTPStatus.noContent)
                } else {
                    return Candidate(name: candidateRequest.candidate, profileUrl: candidateRequest.profileUrl)
                        .save(on: req.db)
                        .transform(to: HTTPStatus.created)
                }
            }
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
