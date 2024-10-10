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
    static var shared = Game()
    
    let errorChanged = PassthroughSubject<Bool, Never>()

    @Published var data: GameData
    
    @Published var stack: [ChipCadeData]
    @Published var registers: [ChipCadeData]

    @Published var flags = CPUFlags()
    
    // The instruction pointer
    @Published var currCodeItemIndex: Int = 0
    @Published var currInstructionIndex: Int = 0
    
    // Stack
    var callStack: [UInt] = []
    
    // Drawing widgets
    var cpuRender = MetalDraw2D();
    var cpuWidget = CPUWidget()
    
    var gcp = GCP()
    var cpu = CPU()
    
    @Published var error = ChipCadeError.none
    @Published var errorCodeItemIndex = 0
    @Published var errorInstructionIndex = 0

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
        data = .init()
        registers = [.unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0), .unsigned16Bit(0),
            .unsigned16Bit(0), // KeyASCII code
            .unsigned16Bit(0), // TouchState
            .signed16Bit(0),   // TouchX
            .signed16Bit(0),   // TouchY
        ]
        stack = []
    }
    
    // Start playback, execute init
    public func play() {
        reset()
                
        gcp.setupGameData(gameData: data)
        
        error = .none
        state = .running
        
        gcp.draw2D.metalView.enableSetNeedsDisplay = false
        gcp.draw2D.metalView.isPaused = false
        
        // init
        while let instruction = getInstruction(), error == .none {
            cpu.executeInstruction(instruction: instruction, game: self, gcp: gcp)
            currInstructionIndex += 1
        }
    }
    
    // Stop playback
    public func stop() {
        reset()

        error = .none
        errorChanged.send(false)

        state = .paused
        gcp.draw2D.metalView.enableSetNeedsDisplay = true
        gcp.draw2D.metalView.isPaused = true
        
        cpuRender.update()
    }
    
    // Stop playback
    public func pause() {
        
        state = .paused
        gcp.draw2D.metalView.enableSetNeedsDisplay = true
        gcp.draw2D.metalView.isPaused = true
        
        cpuRender.update()
    }
    
    // Called when running from the updater
    public func update() {
        currCodeItemIndex = 1
        currInstructionIndex = 0
        
        // init
        while let instruction = getInstruction() {
            cpu.executeInstruction(instruction: instruction, game: self, gcp: gcp)
            currInstructionIndex += 1
        }
        cpuRender.update()
    }
    
    // Execute the current instruction
    public func executeInstruction() {
        if let instruction = getInstruction() {
            cpu.executeInstruction(instruction: instruction, game: self, gcp: gcp)
            gcp.draw2D.update()
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
    
    // Returns the codeItem of a given name
    func getCodeItem(byName name: String) -> CodeItem? {
        return data.codeItems.first { $0.name == name }
    }
    
    // Returns the codeItem of a given name
    func getCodeItemIndex(byItem item: CodeItem) -> Int? {
        return data.codeItems.firstIndex { $0 === item }
    }
    
    // Returns the spriteItem of a given name
    func getSpriteItem(spriteName: String) -> SpriteItem? {
        return data.spriteItems.first { $0.name == spriteName }
    }
    
    // Get the memory value at the given address
    func getMemoryValue(memoryItemName: String, offset: Int) -> ChipCadeData? {
        if let memoryItem = data.getMemoryItem(name: memoryItemName) {
            if offset < memoryItem.memory.count {
                return memoryItem.memory[offset]
            }
        }
        return nil
    }
    
    // Set the memory value at the given address
    func setMemoryValue(memoryItemName: String, offset: Int, value: ChipCadeData) -> Bool {
        if let memoryItem = data.getMemoryItem(name: memoryItemName) {
            if offset < memoryItem.memory.count {
                memoryItem.memory[offset] = value
                return false
            }
        }
        return true
    }
    
    // Draw the game
    public func drawGame()
    {
        if state == .running {
            update()
        }
        gcp.draw()
    }
    
    public func drawCPU()
    {
        cpuWidget.draw(draw2D: cpuRender, game: self)
    }
    
    public func reset() {
        stack = []
        callStack = []
        
        flags.clearFlags()
                
        for i in 0...7 {
            registers[i] = ChipCadeData.unsigned16Bit(0)
        }
        
        currCodeItemIndex = 0
        currInstructionIndex = 0
    }
    
    // Set an active eeror
    func setError(_ error: ChipCadeError) {
        self.error = error
        errorCodeItemIndex = currCodeItemIndex
        errorInstructionIndex = currInstructionIndex
        
        pause()
        errorChanged.send(true)
    }
}
