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
    
    let pathUnderTest = "candidates"

    override func setUpWithError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! setupTestEnvironment(application: app)
    }

    override func tearDownWithError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! clearAppState(application: app)
    }
    
    func testAddCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
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
    
    func testUpdateCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let oldProfileUrl = "https://example-old.com"
        
        XCTAssertNotEqual(oldProfileUrl, PROFILE_URL)
        
        try! createCandidate(on: app.db, named: CANDIDATE, with: "")
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }
    
    func testAddDuplicateCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE, with: PROFILE_URL)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
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
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: NO_CANDIDATE, profileUrl: PROFILE_URL)
        
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
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: BAD_CANDIDATE_SYMBOLS, profileUrl: PROFILE_URL)
        
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
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: BAD_CANDIDATE_NUMBERS, profileUrl: PROFILE_URL)
        
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
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: BAD_CANDIDATE_LOWERCASE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testAddCandidateProfileNoDomain() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL_NO_DOMAIN)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testAddCandidateProfileHttp() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL_HTTP)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testAddCandidateProfileIpfs() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL_IPFS)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testAddCandidateBadProfile() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: INVALID_PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testAddCandidateNoProfile() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: NO_PROFILE_URL)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testAddCandidateBadProfileScheme() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: INVALID_PROFILE_URL_SCHEME)
        
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
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
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
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
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
