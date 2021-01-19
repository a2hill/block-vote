@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    let ADMIN_ADDRESS = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
    let REGULAR_ADDRESS = "1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX"
    let SIGNATURE = "abcd"
    
    let CANDIDATE = "JOHN DOE"
    let BAD_CANDIDATE_SYMBOLS = "JOHN_DOE"
    let BAD_CANDIDATE_NUMBERS = "J0HN D0E"
    let BAD_CANDIDATE_LOWERCASE = "john doe"
    let NO_CANDIDATE = ""
    
    let QUANTITY = 22.22
    
    
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
        
        let voteRequest = VoteRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notModified)
        })
    }
    
    // Requires running `npm run mock-servernode --verion` first. node ~v10.15.0
    func testVoteSuccess() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
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
    
    func testDeleteCandidateUnauthorized() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
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
        
        let voteRequest = VoteRequest(id: ADMIN_ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.DELETE, "candidates", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }
}
