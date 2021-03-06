//
//  File.swift
//  
//
//  Created by Austin Hill on 2/8/21.
//
import Vapor

public struct ConfigurationError: DebuggableError {
    enum Value: String {
        case badAddress
        case noAdmin
        case minVersion
        
        var reasonPhrase: String {
            switch self {
            case .badAddress: return "The supplied address is not a valid Base58Check address"
            case .noAdmin: return "You must supply at least one admin address"
            case .minVersion: return "To run this service you must use minimum OSX 15.4.0"
            }
        }
    }
    
    public var identifier: String
    public var reason: String
    public var source: ErrorSource?
    
    var value: Value
    
    init(_ value: Value, reason: String? = nil) {
        self.value = value
        self.reason = reason ?? value.reasonPhrase
        
        self.identifier = value.rawValue
    }
}
