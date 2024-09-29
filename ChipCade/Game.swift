//
//  Game.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import Combine
import SwiftUI

public class Game : ObservableObject, Codable
{
    @Published var codeItems: [CodeItem]
    @Published var spriteItems: [MemoryItem]
    @Published var dataItems: [MemoryItem]
    @Published var textItems: [MemoryItem]
    
    @Published var stack: [ChipCadeData]

    private enum CodingKeys: String, CodingKey {
        case memory
        case codeItems
        case spriteItems
        case dataItems
        case textItems
        case stack
    }
    
    init() {
        self.codeItems = [CodeItem(name: "main")]
        self.spriteItems = []
        self.dataItems = []
        self.textItems = []
        self.stack = []
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        codeItems = try container.decode([CodeItem].self, forKey: .codeItems)
        spriteItems = try container.decode([MemoryItem].self, forKey: .spriteItems)
        dataItems = try container.decode([MemoryItem].self, forKey: .dataItems)
        textItems = try container.decode([MemoryItem].self, forKey: .textItems)
        stack = try container.decode([ChipCadeData].self, forKey: .stack)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(codeItems, forKey: .codeItems)
        try container.encode(spriteItems, forKey: .spriteItems)
        try container.encode(dataItems, forKey: .dataItems)
        try container.encode(textItems, forKey: .textItems)
        try container.encode(stack, forKey: .stack)
    }
    
    public func execute() {
        self.stack = []
        execute_instruction(codeItemIndex: 0, instructionIndex: 0)
    }
    
    public func execute_instruction(codeItemIndex: Int, instructionIndex: Int) {
        switch self.codeItems[codeItemIndex].codes[instructionIndex] {
            case .push(let value) : self.stack.append(value)
            default: break
        }
    }
}
