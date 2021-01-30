@testable import App
import XCTVapor
import Fluent
import Vapor

final class AppTests: XCTestCase {
    
    let ADMIN_ADDRESS = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
    let REGULAR_ADDRESS = "1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX"
    let BAD_ADDRESS = "000000"
    let SIGNATURE = "abcd"
    
    let CANDIDATE = "JOHN DOE"
    let BAD_CANDIDATE_SYMBOLS = "JOHN_DOE"
    let BAD_CANDIDATE_NUMBERS = "J0HN D0E"
    let BAD_CANDIDATE_LOWERCASE = "john doe"
    let NO_CANDIDATE = ""
    
    let QUANTITY = 22.22
    
    override func setUp() {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! deleteVotes(on: app.db)
        try! deleteCandidates(on: app.db)
    }
    
    override func tearDown() {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try! deleteVotes(on: app.db)
        try! deleteCandidates(on: app.db)
    }
    
    // Requires running `npm run mock-servernode --verion` first. node ~v10.15.0
    func testVoteCandidateDoesNotExist() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: REGULAR_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "votes", beforeRequest: { req in
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
        
        try app.test(.POST, "votes", beforeRequest: { req in
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
        
        try app.test(.POST, "votes", beforeRequest: { req in
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
        
        try app.test(.POST, "votes", beforeRequest: { req in
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
        
        try app.test(.POST, "votes", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testVoteBadAddress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: BAD_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "votes", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
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
        
        try app.test(.POST, "votes", beforeRequest: { req in
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
        
        try app.test(.POST, "votes", beforeRequest: { req in
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
        try app.test(.GET, "votes") { res in
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
        try app.test(.GET, "votes/JOHN%20DOE") { res in
            XCTAssertEqual(res.status, .ok)
            let listedVotes = try res.content.decode(Page<Vote>.self)
            XCTAssertEqual(listedVotes.items, votes)
         }
    }
    
    func testListVotesForNonExistantCandidate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        try app.test(.GET, "votes/JOHN%20DOE") { res in
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
        
        try app.test(.GET, "votes/JOHN%20DOE/sum") { res in
            XCTAssertEqual(res.status, .notFound)
         }
    }
}
