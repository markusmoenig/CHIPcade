//
//  Stack.swift
//  CHIPcade
//
//  Created by Markus Moenig on 28/10/24.
//

enum StackValue {
    case address(String)
    case value(ChipCadeData)
    
    func toString() -> String {
        switch self {
        case .address(let address): return address
        case .value(let value): return value.description()
        }
    }
}
