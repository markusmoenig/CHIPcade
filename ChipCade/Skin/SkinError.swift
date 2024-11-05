//
//  Error.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/11/24.
//

import Foundation

public final class SkinError {
    
    public enum ErrorType {
        case warning
        case error
    }
    
    enum Failures: Swift.Error {
        case parseFailure
    }
    
    public let type            : ErrorType
    public let line            : Int
    public let message         : String
    
    private let token          : Token?
    
    public init(type: ErrorType = .error, line: Int, message: String) {
        self.type = type
        self.line = line
        self.message = message
        token = nil
    }

    init(type: ErrorType = .error, token: Token, message: String) {
        self.type = type
        self.token = token
        self.line = token.line
        self.message = message
    }
}

public final class Errors {
    public var errors : [SkinError] = []
    
    public init() {
        
    }
    
    public func add(type: SkinError.ErrorType = .error, line: Int, message: String) {
        errors.append(SkinError(type: type, line: line, message: message))
    }
    
    func add(type: SkinError.ErrorType = .error, token: Token, message: String) {
        errors.append(SkinError(type: type, token: token, message: message))
    }
}
