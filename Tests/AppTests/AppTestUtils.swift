//
//  AppTestUtils.swift
//  
//
//  Created by Austin Hill on 1/28/21.
//

@testable import App
import Vapor
import Fluent
import Foundation

let ADMIN_ADDRESS_1 = "1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"
let ADMIN_ADDRESS_2 = "12T4oSNd4t9ty9fodgNd47TWhK35pAxDYN"
let REGULAR_ADDRESS = "1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX"
let EXCLUDED_ADDRESS_1 = "1NDyJtNTjmwk5xPNhjgAMu4HDHigtobu1s"
let EXCLUDED_ADDRESS_2 = "12KkeeRkiNS13GMbg7zos9KRn9ggvZtZgx"
let INVALID_ADDRESS = "000000"
let EMPTY_ADDRESS = ""

let CANDIDATE = "JOHN DOE"
let BAD_CANDIDATE_SYMBOLS = "JOHN_DOE"
let BAD_CANDIDATE_NUMBERS = "J0HN D0E"
let BAD_CANDIDATE_LOWERCASE = "john doe"
let NO_CANDIDATE = ""

let SIGNATURE = "abcd"
let NO_SIGNATURE = ""

let PROFILE_URL = "https://example.com"
let PROFILE_URL_HTTP = "https://example.com"
let PROFILE_URL_NO_DOMAIN = "https://example"
let PROFILE_URL_IPFS = "ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/wiki/Vincent_van_Gogh.html"
let INVALID_PROFILE_URL = "example"
let INVALID_PROFILE_URL_SCHEME = "ftp://example.com"
let NO_PROFILE_URL = ""

func createCandidate(on db: Database, named name: String, with profileUrl: String = "http://example.com") throws {
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

func clearAppState(application: Application) throws {
    try! setupTestEnvironment(application: application)
    try! configure(application)
    
    // Clear db
    try! deleteCandidates(on: application.db)
    try! deleteVotes(on: application.db)
    
    // Clear config process vars
    try! clearTestEnvironment(application: application)
}

func setupTestEnvironment(application: Application) throws {
    try! clearTestEnvironment(application: application)
    Environment.process.adminAddresses = ADMIN_ADDRESS_1
}

func clearTestEnvironment(application: Application) throws {
    Environment.process.excludedVoters = nil
}
