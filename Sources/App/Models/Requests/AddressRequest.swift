//
//  AddressRequest.swift
//  
//
//  Created by Austin Hill on 1/10/21.
//

import Vapor

struct AddressRequest: Content {
    var address: String
}

extension AddressRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("address", as: String.self, is: .address)
    }
}
