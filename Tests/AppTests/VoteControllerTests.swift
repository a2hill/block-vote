@testable import App
import XCTVapor
import Fluent
import Vapor

final class VoteControllerTests: XCTestCase {
    
    let QUANTITY = 22.22
    let pathUnderTest = "votes"
    
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
    
    // Requires running `npm run mock-servernode --verion` first. node ~v10.15.0
    func testVoteCandidateDoesNotExist() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testVoteEmptyCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: NO_CANDIDATE)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testVoteBadCandidateSymbols() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_SYMBOLS)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testVoteBadCandidateNumbers() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_NUMBERS)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testVoteBadCandidateLowercase() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_LOWERCASE)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testVoteBadAddress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: INVALID_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testVoteExcludedAddress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.excludedVoters = EXCLUDED_ADDRESS_1
        try! configure(app)
        
        let voteRequest = VoteRequest(id: EXCLUDED_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    // Requires running `npm run mock-servernode --verion` first. node ~v10.15.0
    func testVoteSuccess() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        let voteResponse = Vote(voteRequest, quantity: QUANTITY)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let returnedVote = try res.content.decode(Vote.self)
            XCTAssertEqual(returnedVote, voteResponse)
        })
    }
    
    func testVoteUpdate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        // Create original vote
        let originalCandidate = "ORIGINAL CANDIDATE"
        try! createCandidate(on: app.db, named:originalCandidate)
        try! createVote(on: app.db, from: REGULAR_ADDRESS, for: originalCandidate, with: QUANTITY, signature: SIGNATURE)
        
        // Create new candidate
        try! createCandidate(on: app.db, named: CANDIDATE)
        
        // Update vote
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        let voteResponse = Vote(voteRequest, quantity: QUANTITY)
        
        try app.test(.POST, pathUnderTest, beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            let returnedVote = try res.content.decode(Vote.self)
            XCTAssertEqual(returnedVote, voteResponse)
        })
    }
    
    func testListVotes() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let votes = try createVotes(on: app.db, for: CANDIDATE)
        try app.test(.GET, pathUnderTest) { res in
            XCTAssertEqual(res.status, .ok)
            let returnedVotes = try res.content.decode(Page<Vote>.self)
            XCTAssertEqual(returnedVotes.items, votes)
         }
        
        try deleteVotes(on: app.db)
    }
    
    func testListVotesForCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try createCandidate(on: app.db, named: CANDIDATE)
        let votes = try createVotes(on: app.db, for: CANDIDATE)
        try app.test(.GET, "\(pathUnderTest)/JOHN%20DOE") { res in
            XCTAssertEqual(res.status, .ok)
            let listedVotes = try res.content.decode(Page<Vote>.self)
            XCTAssertEqual(listedVotes.items, votes)
         }
    }
    
    func testListVotesForNonExistantCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try app.test(.GET, "\(pathUnderTest)/JOHN%20DOE") { res in
            XCTAssertEqual(res.status, .notFound)
         }
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
        
        try app.test(.GET, "\(pathUnderTest)/JOHN%20DOE/sum") { res in
            XCTAssertEqual(res.status, .notFound)
         }
    }
}
