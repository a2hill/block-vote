//
//  CandidateRequest.swift
//  
//
//  Created by Austin Hill on 1/29/21.
//

import Fluent
import Vapor

final class CandidateRequest: SignedRequest {
    
    var id: String?
    var signature: String
    var candidate: String
    var profileUrl: String
    
    init(id: String, signature: String, candidate: String, profileUrl: String) {
        self.id = id
        self.signature = signature
        self.candidate = candidate
        self.profileUrl = profileUrl
    }
}

extension CandidateRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("signature", as: String.self, is: .alphanumeric)
        validations.add("candidate", as: String.self, is: .candidate)
        validations.add("id", as: String.self, is: .address)
        validations.add("profileUrl", as: String.self, is: .url)
    }
}
