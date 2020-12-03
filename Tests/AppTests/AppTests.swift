@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    let ADDRESS = "1111"
    let SIGNATURE = "abcd"
    let CANDIDATE = "JOHN DOE"
    let QUANTITY = 22.22
    
    func testHelloWorld() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
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
}
