//
//  CandidateControllerTests.swift
//  AppTests
//
//  Created by Austin Hill on 1/28/21.
//

@testable import App
import XCTVapor
import Fluent
import Vapor

class CandidateControllerTests: XCTestCase {
    
    let ADMIN_ADDRESS = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
    let REGULAR_ADDRESS = "1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX"
    let CANDIDATE = "JOHN DOE"
    let SIGNATURE = "abcd"

    override func setUpWithError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        try! deleteCandidates(on: app.db)
    }

    override func tearDownWithError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        try! deleteCandidates(on: app.db)
    }
    
    func testAddCandidateUnauthorized() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    func testAddCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testAddDuplicateCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let voteRequest = VoteRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notModified)
        })
    }

    func testDeleteCandidateUnauthorized() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testDeleteCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let voteRequest = VoteRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }
    
    func testDeleteNoneExistantCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testSumVotes() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try createCandidate(on: app.db, named: CANDIDATE)
        let votes = try createVotes(on: app.db, for: CANDIDATE)
        try app.test(.GET, "votes/JOHN%20DOE/sum") { res in
            XCTAssertEqual(res.status, .ok)
            let count = Double(res.body.string)
            let voteTotal = votes.reduce(0.0) { $0 + $1.quantity }
            XCTAssertEqual(count, voteTotal)
         }
    }
    
    func testSumVotesForNonExistantCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try app.test(.GET, "votes/JOHN%20DOE/sum") { res in
            XCTAssertEqual(res.status, .notFound)
         }
    }
    
    func createVotes(on db: Database, for candidate: String) throws -> [Vote] {
        let votes = [
            Vote(id: "1234", signature: "abcd", candidate: candidate, quantity: 10),
            Vote(id: "4567", signature: "abcd", candidate: candidate, quantity: 10),
            Vote(id: "890", signature: "abcd", candidate: candidate, quantity: 10)
        ]
        _ = try! votes.create(on: db).wait()
        return votes
    }

    func createCandidate(on db: Database, named name: String) throws {
        try Candidate(name: name).create(on: db).wait()
    }
    
    func deleteCandidates(on db: Database) throws {
        _ = try! Candidate.query(on: db).all()
            .map {
                $0.delete(on: db)
            }
            .wait()
    }
}
