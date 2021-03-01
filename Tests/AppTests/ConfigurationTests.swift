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

    func testSingleAdmin() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.adminAddresses = ADMIN_ADDRESS_1
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testMultipleAdmin() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.adminAddresses = "\(ADMIN_ADDRESS_1),\(ADMIN_ADDRESS_2)"
        try! configure(app)
        
        let candidateRequest = CandidateRequest(id: ADMIN_ADDRESS_2, signature: SIGNATURE, candidate: CANDIDATE, profileUrl: PROFILE_URL)
        
        try app.test(.POST, "candidates", beforeRequest: { req in
            try req.content.encode(candidateRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
    
    func testNoAdmin() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.adminAddresses = nil
        
        XCTAssertThrowsError( try configure(app)) { error in
            XCTAssertEqual((error as? ConfigurationError)?.value, ConfigurationError.Value.noAdmin)
        }
    }
    
    func testEmptyAdmin() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.adminAddresses = EMPTY_ADDRESS
        
        XCTAssertThrowsError( try configure(app)) { error in
            XCTAssertEqual((error as? ConfigurationError)?.value, ConfigurationError.Value.badAddress)
        }
    }
    
    func testBadAdmin() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.adminAddresses = INVALID_ADDRESS
        XCTAssertThrowsError( try configure(app)) { error in
            XCTAssertEqual((error as? ConfigurationError)?.value, ConfigurationError.Value.badAddress)
        }
    }
    
    func testSingleExcludedAddress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.excludedVoters = EXCLUDED_ADDRESS_1
        try! configure(app)
        
        let voteRequest = VoteRequest(id: EXCLUDED_ADDRESS_1, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "votes", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    func testMultipleExcludedAddresses() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.excludedVoters = "\(EXCLUDED_ADDRESS_1),\(EXCLUDED_ADDRESS_2)"
        try! configure(app)
        
        let voteRequest = VoteRequest(id: EXCLUDED_ADDRESS_2, signature: SIGNATURE, candidate: CANDIDATE)
        
        try app.test(.POST, "votes", beforeRequest: { req in
            try req.content.encode(voteRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.unauthorized)
        })
    }
    
    func testBadExclusion() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        Environment.process.excludedVoters = INVALID_ADDRESS
        XCTAssertThrowsError( try configure(app)) { error in
            XCTAssertEqual((error as? ConfigurationError)?.value, ConfigurationError.Value.badAddress)
        }
    }
}
