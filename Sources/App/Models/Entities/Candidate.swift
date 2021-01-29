//
//  Candidate.swift
//  
//
//  Created by Austin Hill on 1/5/21.
//

import Fluent
import Vapor

final class Candidate: Model, Content {
    static let schema = "candidates"
    
    @ID(custom: "name", generatedBy: .user)
    var id: String?

    init() { }

    init(name: String? = nil) {
        self.id = name
    }
}

extension Candidate: Equatable {
    static func == (lhs: Candidate, rhs: Candidate) -> Bool {
        return lhs.id == rhs.id
    }
}

