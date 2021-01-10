//
//  VoteMiddleware.swift
//  
//
//  Created by Austin Hill on 1/7/21.
//

import Vapor
import Base58Swift

struct VoteMiddleware: Middleware {

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            try VoteRequest.validate(content: request)
            return next.respond(to: request)
        } catch {
            return request.eventLoop.future(error: Abort(.badRequest))
        }
    }
}

extension Validator where T == String {
    public static var address: Validator = base58Check
    
    public static var candidate: Validator = .characterSet(.uppercaseLetters + .whitespaces)
    
    public static var base58Check: Validator {
        .init {
            ValidatorResults.Base58(bytes: Base58.base58CheckDecode($0))
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

extension VoteRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("signature", as: String.self, is: .alphanumeric)
        validations.add("candidate", as: String.self, is: .candidate)
        validations.add("id", as: String.self, is: .address)
    }
}
