//
//  AddressValidator.swift
//  
//
//  Created by Austin Hill on 1/10/21.
//

import Vapor
import Base58Swift

extension Validator where T == String {
    public static var address: Validator = base58Check
    public static var base58Check: Validator {
        .init { base58CCheckString in
            var results: [UInt8]? = nil
            if !base58CCheckString.isEmpty {
                results = Base58.base58CheckDecode(base58CCheckString)
            }
            return ValidatorResults.Base58(bytes: results)
        }
    }
}

extension ValidatorResults {
    struct Base58 {
        public let bytes: [UInt8]?
    }
}

extension ValidatorResults.Base58: ValidatorResult {
    public var isFailure: Bool {
        guard let _ = self.bytes else {
            return true
        }
        return false
    }
    
    public var successDescription: String? {
        "is base58check encoded"
    }
    
    public var failureDescription: String? {
        "is not a valid base58check encoding"
    }
}
