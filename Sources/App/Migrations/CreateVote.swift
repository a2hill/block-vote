//
//  File.swift
//  
//
//  Created by Austin Hill on 1/5/21.
//

import Fluent

struct CreateVote: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("vote")
            .field("address", .string, .identifier(auto: false), .required)
            .field("signature", .string, .required)
            .field("candidate", .string, .required)
            .field("quantity", .double, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("vote").delete()
    }
}

