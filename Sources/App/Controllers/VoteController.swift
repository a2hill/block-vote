//
//  File.swift
//  
//
//  Created by Hill, Austin on 11/28/20.
//

import Vapor
import Fluent

struct VoteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let vote = routes
            .grouped("votes")
        
        // Get
        vote.get(use: listVotes)
        vote.group(":candidate") { candidate in
            candidate.group("sum") { action in
                action.get(use: sumAllVotesForCandidate)
            }
            candidate.get(use: getAllVotesForCandidate)
        }
        
        // Create
        vote.group([VoteMiddleware(), SignatureAuthenticator(), VoteRequest.guardMiddleware(throwing: Abort(.unauthorized, reason: "Address, message, and signature do not match"))]) { protected in
            protected.post(use: create)
        }
    }

    func listVotes(req: Request) throws -> EventLoopFuture<Page<Vote>> {
        return Vote.query(on: req.db).paginate(for: req)
    }

    func create(req: Request) throws -> EventLoopFuture<Vote> {
        
        let voteRequest = try req.auth.require(VoteRequest.self)
        
        let countedVote = try CanidateLogic.getCandidate(by: voteRequest.candidate, db: req.db)
            .unwrap(or: Abort(.notFound, reason: "candidate does not exist"))
            .flatMap { _ in
                req.blockchain.getBalance(address: voteRequest.id!)
            }
            .and(Vote.find(voteRequest.id!, on: req.db))
            .flatMap { (balance: Double, existingVote: Vote?) -> EventLoopFuture<Vote> in
                // Vote already exists. Changing candidate.
                if let existingVote = existingVote {
                    existingVote.candidate = voteRequest.candidate
                    return existingVote.update(on: req.db).transform(to: existingVote)
                }
                
                let newVote = Vote(voteRequest, quantity: balance)
                return newVote.save(on: req.db).transform(to: newVote)
            }
        
        return countedVote
    }
    
    func getAllVotesForCandidate(req: Request) throws -> EventLoopFuture<Page<Vote>> {
        let candidateName = req.parameters.get("candidate")!
        let candidate = try CanidateLogic.getCandidate(by: candidateName, db: req.db)
            .unwrap(or: Abort(.notFound, reason: "Candidate does not exist"))
        
        let votes = candidate.flatMap { _ in
            Vote.query(on: req.db).filter(\.$candidate == candidateName).paginate(for: req)
        }
        return votes
    }
    
    func sumAllVotesForCandidate(req: Request) throws -> EventLoopFuture<String> {
        let candidateName = req.parameters.get("candidate")!
        let candidate = try CanidateLogic.getCandidate(by: candidateName, db: req.db)
            .unwrap(or: Abort(.notFound, reason: "Candidate does not exist"))
        
        let voteCount = candidate.flatMap { _ in
            Vote.query(on: req.db).filter(\.$candidate == candidateName).sum(\.$quantity)
                .unwrap(orReplace: 0.0)
                .map { value in
                    String(value)
                }
        }
        
        return voteCount
    }
}
