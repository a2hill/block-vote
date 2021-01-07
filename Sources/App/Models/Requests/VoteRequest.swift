//
//  VoteRequest.swift
//  
//
//  Created by Austin Hill on 1/5/21.
//
import Fluent
import Vapor

final class VoteRequest: Model, Content, Authenticatable {
    
    static let schema = "voteRequest"
    
    @ID(custom: "address", generatedBy: .user)
    var id: String?

    @Field(key: "signature")
    var signature: String
    
    @Field(key: "candidate")
    var candidate: String

    init() { }

    init(id: String, signature: String, candidate: String) {
        self.id = id
        self.signature = signature
        self.candidate = candidate
    }
}
