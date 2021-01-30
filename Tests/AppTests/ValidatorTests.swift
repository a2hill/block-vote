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

}
