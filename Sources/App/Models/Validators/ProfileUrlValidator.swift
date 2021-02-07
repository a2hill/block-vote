//
//  ProfileUrlValidator.swift
//  
//
//  Created by Austin Hill on 2/7/21.
//

import Vapor

extension Validator where T == String {
    public static var validScheme: Validator {
        .init {
            guard
                let url = Foundation.URL(string: $0),
                let scheme = url.scheme,
                let _ = ValidatorResults.ValidScheme.Schemes(rawValue: scheme)
            else {
                
                return ValidatorResults.ValidScheme(isValidScheme: false)
            }
            return ValidatorResults.ValidScheme(isValidScheme: true)
        }
    }
}

extension ValidatorResults {
    
    public struct ValidScheme {
        enum Schemes: String, CaseIterable {
            case http = "http"
            case https = "https"
            case ipfs = "ipfs"
        }
        
        public let isValidScheme: Bool
    }
}

extension ValidatorResults.ValidScheme: ValidatorResult {
    
    public var isFailure: Bool {
        !self.isValidScheme
    }

    public var successDescription: String? {
        "is a valid URL scheme"
    }

    public var failureDescription: String? {
        let cases = ValidatorResults.ValidScheme.Schemes.allCases.map {
            $0.rawValue
        }
        return "is not a valid URL scheme. Must be one of \(cases)"
    }
}
