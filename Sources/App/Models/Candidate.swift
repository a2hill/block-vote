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
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

