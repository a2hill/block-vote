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
    
    func testAddCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testAddCandidateUnauthorized() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    func testAddDuplicateCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notModified)
        })
    }
    
    func testDeleteCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }

    func testDeleteCandidateUnauthorized() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let candidateRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testDeleteNoneExistantCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testSumVotesForCandidate() throws {
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
    
    func testListAllCandidates() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateNames = [
            "CANDIDATE ONE",
            "CANDIDATE TWO",
            "CANDIDATE THREE",
            "CANDIDATE FOUR",
            "CANDIDATE FIVE",
        ]
        let candidates = try! createCandidates(on: app.db, names: candidateNames)
        
        try app.test(.GET, "candidates") { res in
            let returnedCandidates = try res.content.decode(Page<Candidate>.self)
            XCTAssertEqual(returnedCandidates.items, candidates)
         }
    }
}
