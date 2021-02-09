//
//  ConfigurationTests.swift
//  AppTests
//
//  Created by Austin Hill on 2/8/21.
//

@testable import App
import XCTVapor
import Vapor

class ConfigurationTests: XCTestCase {
    
    let ADMIN_ADDRESS_1 = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
    let ADMIN_ADDRESS_2 = "12T4oSNd4t9ty9fodgNd47TWhK35pAxDYN"
    let EXCLUDED_ADDRESS_1 = "1NDyJtNTjmwk5xPNhjgAMu4HDHigtobu1s"
    let EXCLUDED_ADDRESS_2 = "12KkeeRkiNS13GMbg7zos9KRn9ggvZtZgx"
    
    let PROFILE_URL = "https://example.com"
    
    let SIGNATURE = "abcd"
    let CANDIDATE = "JOHN DOE"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSingleAdmin() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//        try! configure(app)
//
//        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
//
//        try app.test(.POST, "candidates", beforeRequest: { req in
//            try req.content.encode(candidateRequest)
//        }, afterResponse: { res in
//            XCTAssertEqual(res.status, .created)
//        })
    }
    
    func testMultipleAdmin() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//        try! configure(app)
//        
//        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_2, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
//        
//        try app.test(.POST, "candidates", beforeRequest: { req in
//            try req.content.encode(candidateRequest)
//        }, afterResponse: { res in
//            XCTAssertEqual(res.status, .created)
//        })
    }
    
    func testBadAdmin() throws {
        
    }
    
    func testSingleExclusion() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: EXCLUDED_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "votes", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    func testMultipleExclusion() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try! configure(app)
        
        let voteRequest = VoteRequest(id: EXCLUDED_ADDRESS_2, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "votes", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    func testBadExclusion() throws {
        
    }
}
