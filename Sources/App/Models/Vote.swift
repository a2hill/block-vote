//
//  File.swift
//  
//
//  Created by Hill, Austin on 11/28/20.
//

import Fluent
import Vapor

final class VoteRequest: Model, Content {
    
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

final class Vote: Model, Content, Equatable {
    
    static let schema = "vote"
    
    @ID(custom: "address", generatedBy: .user)
    var id: String?

    @Field(key: "signature")
    var signature: String
    
    @Field(key: "candidate")
    var candidate: String
    
    @Field(key: "quantity")
    var quantity: Double

    init() { }
    
    convenience init(_ voteRequest: VoteRequest, quantity: Double) {
        self.init(id: voteRequest.id, signature: voteRequest.signature, candidate: voteRequest.candidate, quantity: quantity)
    }

    init(id: String?, signature: String, candidate: String, quantity: Double) {
        self.id = id
        self.signature = signature
        self.candidate = candidate
        self.quantity = quantity
    }
    
    static func == (lhs: Vote, rhs: Vote) -> Bool {
        return lhs.id == rhs.id &&
        lhs.signature == rhs.signature &&
        lhs.candidate == rhs.candidate &&
        lhs.quantity ==  rhs.quantity
    }
}

