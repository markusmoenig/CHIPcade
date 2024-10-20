//
//  Error.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

enum ChipCadeError: Error {
    case none
    case invalidMemoryAddress
    case invalidCodeAddress
    case invalidComparison
    case invalidArithmetic
    case invalidImageGroup
    case invalidLayerIndex
    case invalidSpriteIndex
    case invalidResolution

    var toString: String {
        switch self {
        case .none:
            return "No error"
        case .invalidMemoryAddress:
            return "Invalid memory address"
        case .invalidCodeAddress:
            return "Invalid code address"
        case .invalidComparison:
            return "Invalid comparison"
        case .invalidImageGroup:
            return "Invalid image group"
        case .invalidArithmetic:
            return "Invalid Arithmetic"
        case .invalidSpriteIndex:
            return "Invalid Arithmetic"
        case .invalidLayerIndex:
            return "Invalid Layer Index"
        case .invalidResolution:
            return "Invalid Resolution"
        }
    }
}
