//
//  File.swift
//  
//
//  Created by Austin Hill on 1/28/21.
//

@testable import App
import Fluent
import Foundation

func createCandidate(on db: Database, named name: String, with profileUrl: String = "http://myprofile.com") throws {
    try Candidate(name: name, profileUrl: profileUrl).create(on: db).wait()
}

func createCandidates(on db: Database, names: [String: String]) throws -> [Candidate] {
    let candidates = names.map { key, value in
        Candidate(name: key, profileUrl: value)
        
    }
    try! candidates.create(on: db).wait()
    
    return candidates
}

func deleteCandidates(on db: Database) throws {
    _ = try! Candidate.query(on: db).all()
        .map {
            $0.delete(on: db)
        }
        .wait()
}

func createVote(on db: Database, from address: String, for candidate: String, with quantity: Double, signature: String) throws {
    let vote = Vote(id: address, signature: signature, candidate: candidate, quantity: quantity)
    try! vote.save(on: db).wait()
}

func createVotes(on db: Database, for candidate: String) throws -> [Vote] {
    let votes = [
        Vote(id: "1234", signature: "abcd", candidate: candidate, quantity: 10),
        Vote(id: "4567", signature: "abcd", candidate: candidate, quantity: 10),
        Vote(id: "890", signature: "abcd", candidate: candidate, quantity: 10)
    ]
    _ = try! votes.create(on: db).wait()
    return votes
}

func deleteVotes(on db: Database) throws {
    _ = try! Vote.query(on: db).all()
        .map {
            $0.delete(on: db)
        }
        .wait()
}
