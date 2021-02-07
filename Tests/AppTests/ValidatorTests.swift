//
//  ValidatorTests.swift
//  AppTests
//
//  Created by Austin Hill on 1/29/21.
//

@testable import App
import XCTVapor
import Fluent
import Vapor

class ValidatorTests: XCTestCase {
    
    let VALID_ADDRESS = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
    let INVALID_ADDRESS: String = "0000"
    
    let VALID_URL_HTTPS = "https://example.com"
    let VALID_URL_HTTP = "https://example.com"
    let VALID_URL_IPFS = "ipfs://example.com"
    let INVALID_URL_FTP = "ftp://example.com"

    func testValidateAddress() throws {
        let result = Validator.address.validate(VALID_ADDRESS)
        XCTAssertFalse(result.isFailure)
        XCTAssertNotNil(result.successDescription)
    }
    
    func testInvalidAddress() throws {
        let result = Validator.address.validate(INVALID_ADDRESS)
        XCTAssertTrue(result.isFailure)
        XCTAssertNotNil(result.failureDescription)
    }

    func testValidateUrlHttps() throws {
        let result = Validator.validScheme.validate(VALID_URL_HTTPS)
        XCTAssertFalse(result.isFailure, result.failureDescription!)
        XCTAssertNotNil(result.successDescription)
    }
    
    func testValidateUrlHttp() throws {
        let result = Validator.validScheme.validate(VALID_URL_HTTP)
        XCTAssertFalse(result.isFailure, result.failureDescription!)
        XCTAssertNotNil(result.successDescription)
    }
    
    func testValidateUrlIpfs() throws {
        let result = Validator.validScheme.validate(VALID_URL_IPFS)
        XCTAssertFalse(result.isFailure, result.failureDescription!)
        XCTAssertNotNil(result.successDescription)
    }
    
    func testInvalidUrl() throws {
        let result = Validator.address.validate(INVALID_URL_FTP)
        XCTAssertTrue(result.isFailure)
        XCTAssertNotNil(result.failureDescription)
    }
}
