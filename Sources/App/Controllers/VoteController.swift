//
//  File.swift
//  
//
//  Created by Hill, Austin on 11/28/20.
//

import Fluent
import Vapor
import Base58Swift
import Foundation

struct VoteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let vote = routes.grouped("vote")
        vote.get(use: index)
        vote.post(use: create)
    }

    func index(req: Request) throws -> EventLoopFuture<[Vote]> {
        return Vote.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Vote> {
        try VoteRequest.validate(content: req)
        let voteRequest = try req.content.decode(VoteRequest.self)
        let countedVote = req.blockchain.validateMessage(address: voteRequest.id!, signature: voteRequest.signature, message: voteRequest.candidate)
            .guard({$0 == true },
                   else: Abort(.badRequest, reason: "Signature does not validate for given message and address"))
            .flatMap { _ in
                return req.blockchain.getBalance(address: voteRequest.id!)
            }.map { balance -> Vote in
                return Vote(voteRequest, quantity: balance)
            }
//            .flatMap { vote in
//                return vote.save(on: req.db).map { vote }
//            }
        
        return countedVote
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Todo.find(req.parameters.get("todoID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
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

//private extension CharacterSet {
//    /// ASCII (byte 0..<128) character set.
//    static var candidate: CharacterSet {
//        .init(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ ")
//    }
//
//    /// Returns an array of strings describing the contents of this `CharacterSet`.
//    var traits: [String] {
//        var desc: [String] = []
//        if isSuperset(of: .whitespaces) {
//            desc.append("whitespace")
//        }
//        if isSuperset(of: .capitalizedLetters) {
//            desc.append("A-Z")
//        }
//        return desc
//    }
//}
