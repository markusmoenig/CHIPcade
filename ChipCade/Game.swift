//
//  Game.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import Combine
import SwiftUI

public enum GameState {
    case running
    case paused
}

public enum SelectionState {
    case code
    case sprite
    case data
}

public class Game : ObservableObject
{
    @Published var data: GameData
    
    @Published var stack: [ChipCadeData]
    @Published var registers: [ChipCadeData]

    // The instruction pointer
    @Published var currCodeItemIndex: Int = 0
    @Published var currInstructionIndex: Int = 0
    var callStack: [UInt] = []

    // Drawing widgets
    
    var render = MetalDraw2D();
    var cpuRender = MetalDraw2D();
    
    var cpuWidget = CPUWidget()
    
    var gcp = GCP()
    var cpu = CPU()
    
    var state = GameState.paused

    var selectionState: SelectionState = .code

    private enum CodingKeys: String, CodingKey {
        case codeItems
        case spriteItems
        case dataItems
        case stack
        case registers
        case palette
    }
        
    init() {
        self.data = .init()
        self.registers = [.unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0)]
        self.stack = []
    }
    
    public func execute() {
        self.reset()

        while let instruction = getInstruction() {
            cpu.executeInstruction(instruction: instruction, game: self, gcp: gcp)
            currInstructionIndex += 1
        }
        render.update()
    }
    
    public func executeInstruction() {
        if let instruction = getInstruction() {
            cpu.executeInstruction(instruction: instruction, game: self, gcp: gcp)
            render.update()
        }
    }
    
    // Gets the current instruction
    public func getInstruction() -> Instruction? {
        // Check if the currCodeItemIndex is within bounds
        guard currCodeItemIndex >= 0 && currCodeItemIndex < data.codeItems.count else {
            return nil
        }

        let codeItem = data.codeItems[currCodeItemIndex]

        // Check if the currInstructionIndex is within bounds for the selected codeItem
        guard currInstructionIndex >= 0 && currInstructionIndex < codeItem.codes.count else {
            return nil
        }

        return codeItem.codes[currInstructionIndex]
    }
    
    // Method to find a CodeItem by name
    func getCodeItem(byName name: String) -> CodeItem? {
        return data.codeItems.first { $0.name == name }
    }
    
    public func drawPreview()
    {
        gcp.draw(draw2D: render)
    }
    
    public func drawCPU()
    {
        cpuWidget.draw(draw2D: cpuRender, game: self)
    }
    
    public func reset() {
        stack = []
        callStack = []
        
        currCodeItemIndex = 0
        currInstructionIndex = 0
    }
}
