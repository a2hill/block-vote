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
    let INVALID_ADDRESS = "0000"
    
    let CANDIDATE = "JOHN DOE"
    let BAD_CANDIDATE_SYMBOLS = "JOHN_DOE"
    let BAD_CANDIDATE_NUMBERS = "J0HN D0E"
    let BAD_CANDIDATE_LOWERCASE = "john doe"
    let NO_CANDIDATE = ""
    
    let SIGNATURE = "abcd"
    let NO_SIGNATURE = ""
    
    let PROFILE_URL = "http://myprofile.com"
    let NO_PROFILE_URL = "http://myprofile.com"
    
    let pathUnderTest = "candidates"

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
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testAddCandidateInvalidAddress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: INVALID_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    func testAddCandidateUnauthorized() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
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
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notModified)
        })
    }
    
    func testAddEmptyCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: NO_CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testAddBadCandidateSymbols() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_SYMBOLS, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testAddBadCandidateNumbers() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_NUMBERS, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testAddBadCandidateLowercase() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_LOWERCASE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testDeleteCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.DELETE, pathUnderTest, beforeRequest: { req in
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
        
        let candidateRequest = CandidateRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.DELETE, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testDeleteNonExistantCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.DELETE, pathUnderTest, beforeRequest: { req in
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
            "CANDIDATE ONE": PROFILE_URL,
            "CANDIDATE TWO": PROFILE_URL,
            "CANDIDATE THREE": PROFILE_URL,
            "CANDIDATE FOUR": PROFILE_URL,
            "CANDIDATE FIVE": PROFILE_URL
        ]
        let candidates = try! createCandidates(on: app.db, names: candidateNames)
        
        try app.test(.GET, pathUnderTest) { res in
            let returnedCandidates = try res.content.decode(Page<Candidate>.self)
            XCTAssertEqual(returnedCandidates.items, candidates)
         }
    }
}
