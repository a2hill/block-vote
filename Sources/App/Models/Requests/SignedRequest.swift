//
//  File.swift
//  
//
//  Created by Austin Hill on 1/29/21.
//

import Fluent
import Vapor

protocol SignedRequest: Content, Authenticatable {
    var id: String? { get set }
    var signature: String { get set }
    var candidate: String { get set }
}

