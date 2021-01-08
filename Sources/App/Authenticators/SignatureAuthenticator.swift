//
//  AddressAuthenticator.swift
//  
//
//  Created by Austin Hill on 1/6/21.
//

import Vapor


struct SignatureAuthenticator: CredentialsAuthenticator {
    
    typealias Credentials = VoteRequest
    
    func authenticate(credentials: Credentials, for request: Request) -> EventLoopFuture<Void> {
        request.blockchain.validateMessage(address: credentials.id!, signature: credentials.signature, message: credentials.candidate)
            .map { validated in
                if validated {
                    request.auth.login(credentials)
                }
            }
    }
}
