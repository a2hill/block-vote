//
//  CandidateValidator.swift
//  
//
//  Created by Austin Hill on 1/10/21.
//

import Vapor

extension Validator where T == String {
    public static var candidate: Validator = .characterSet(.uppercaseLetters + .whitespaces) && !.empty
}
