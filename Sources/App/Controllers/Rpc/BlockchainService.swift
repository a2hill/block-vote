//
//  BlockchainService.swift
//  
//
//  Created by Hill, Austin on 11/28/20.
//

import Vapor
import Foundation

struct BlockchainService {
    
    let client: Client
    
    enum Method: String {
        case verifyMessage = "verifymessage"
        case getBalance = "getbalance"
    }
    public typealias Result = ResultType<RPCObject, Error>

    
    public struct Error: Swift.Error, Equatable {
        public let kind: Kind
        public let description: String

        init(kind: Kind, description: String) {
            self.kind = kind
            self.description = description
        }

        internal init(_ error: JSONError) {
            self.init(kind: JSONErrorCode(rawValue: error.code).map { Kind($0) } ?? .otherServerError, description: error.message)
        }

        public enum Kind {
            case invalidMethod
            case invalidParams
            case invalidRequest
            case invalidServerResponse
            case otherServerError

            internal init(_ code: JSONErrorCode) {
                switch code {
                case .invalidRequest:
                    self = .invalidRequest
                case .methodNotFound:
                    self = .invalidMethod
                case .invalidParams:
                    self = .invalidParams
                case .parseError:
                    self = .invalidServerResponse
                case .internalError, .other:
                    self = .otherServerError
                }
            }
        }
    }

    func validateMessage(address: String, signature: String, message: String) -> EventLoopFuture<Bool> {
        encodeRequest(
            method: .verifyMessage,
            params: RPCObject([address, signature, message])
        ).map { result in
            switch result {
            case .success (let response):
                switch response {
                case .bool(let value):
                    return value
                default:
                    print(response)
                    return false
                }
            case .failure(let error):
                print(error.localizedDescription)
                return false
            }
        }
    }
    
    func getBalance(address: String) -> EventLoopFuture<Double> {
        encodeRequest(method: .getBalance, params: RPCObject(address))
            .map { result in
                switch result {
                case .success(let response):
                    switch response {
                    case .double(let value):
                        return value
                    default:
                        print(response)
                        return 0
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    return 0
                }
            }
    }
    
    private func encodeRequest(method: Method, params: RPCObject) -> EventLoopFuture<Result> {
        let reqId = String(Int.random())
        let result = self.client.post("http://localhost:3333/") { req in
            let json = JSONRequest(id: reqId, method: method.rawValue, params: JSONObject(params))
            try req.content.encode(json)
        }.flatMapThrowing { res in
            try res.content.decode(JSONResponse.self)
        }.guard({ json in json.id == reqId},
            else: Abort(.badRequest, reason: "request id mistmatch")
        ).map { json in
            Result(json)
        }
        
        return result
    }
}

extension Request {
    var blockchain: BlockchainService {
        .init(client: self.client)
    }
}

internal extension ResultType where Value == RPCObject, Error == BlockchainService.Error {
    init(_ response: JSONResponse) {
        if let result = response.result {
            self = .success(RPCObject(result))
        } else if let error = response.error {
            self = .failure(BlockchainService.Error(error))
        } else {
            self = .failure(BlockchainService.Error(kind: .invalidServerResponse, description: "invalid server response"))
        }
    }
}
