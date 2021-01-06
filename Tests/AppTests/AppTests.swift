@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    let ADDRESS = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
    let SIGNATURE = "abcd"
    
    let CANDIDATE = "JOHN DOE"
    let BAD_CANDIDATE_SYMBOLS = "JOHN_DOE"
    let BAD_CANDIDATE_NUMBERS = "J0HN D0E"
    let BAD_CANDIDATE_LOWERCASE = "john doe"
    
    let QUANTITY = 22.22
    
    
    // Requires running `npm run mock-servernode --verion` first. node ~v10.15.0
    func testEndToEnd() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        
        let voteRequest = VoteRequest(id: ADDRESS, signature: SIGNATURE, candidate: CANDIDATE)
        let voteResponse = Vote(voteRequest, quantity: QUANTITY)
        
        try app.test(.POST, "vote", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let returnedVote = try res.content.decode(Vote.self)
            XCTAssertEqual(returnedVote, voteResponse)
        })
    }
    
    func testBadCandidateSymbol() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_SYMBOLS)
        
        try app.test(.POST, "vote", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testBadCandidateNumbers() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_NUMBERS)
        
        try app.test(.POST, "vote", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
    
    func testBadCandidateLowercase() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: ADDRESS, signature: SIGNATURE, candidate: BAD_CANDIDATE_LOWERCASE)
        
        try app.test(.POST, "vote", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.badRequest)
        })
    }
}
