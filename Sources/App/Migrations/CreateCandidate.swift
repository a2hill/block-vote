//
//  CreateCandidate.swift
//  
//
//  Created by Austin Hill on 1/5/21.
//

import Fluent

struct CreateCandidate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("candidates")
            .field("name", .string, .identifier(auto: false), .required)
            .field("profileUrl", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("candidates").delete()
    }
}
