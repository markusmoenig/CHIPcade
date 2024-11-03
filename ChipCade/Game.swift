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
    
    let errorChanged = PassthroughSubject<ChipCadeError, Never>()
    let codeTextChanged = PassthroughSubject<(), Never>()
    let codeLineChanged = PassthroughSubject<Int, Never>()

    @Published var data: GameData
    
    @Published var stack: [StackValue]
    
    var registers: [ChipCadeData]
    var flags = CPUFlags()
    
    // The instruction pointer
    var currCodeItemIndex: Int = 0
    var currInstructionIndex: Int = 0
    
    var prevCodeItemIndex: Int = 0
    var prevInstructionIndex: Int = 0
    
    // Drawing widgets
    var cpuRender = MetalDraw2D();
    var cpuWidget = CPUWidget()
    
    var gcp = GCP()
    var cpu = CPU()

    var error = ChipCadeError.none
    var errorCodeItemIndex = 0
    var errorInstructionIndex = 0
    var errorInstructionType: InstructionType? = nil

    /// Time between updates
    let deltaTimeInMs: Int = Int((1.0 / 60.0) * 1000.0)

    // Game State
    var state = GameState.paused

    // The selection state in the editor
    var selectionState: SelectionState = .code

    // Indicates if the last CMP was unsigned. Needed for later conditional flag evaluation.
    var lastCMPWasUnsigned: Bool = false
    
    var scriptEditor: ScriptEditor? = nil
    var currentCodeItemText = ""
    
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
        cpu.game = self
    }
    
    // Start playback, execute init
    public func play() {
        reset()
             
        prevCodeItemIndex = currCodeItemIndex
        prevInstructionIndex = currInstructionIndex
        
        currCodeItemIndex = 0
        currInstructionIndex = 0
        
        gcp.setupGameData(gameData: data)
        
        error = .none
        state = .running
        
        gcp.draw2D.metalView.enableSetNeedsDisplay = false
        gcp.draw2D.metalView.isPaused = false
        
        // init
        execute()
        
        currCodeItemIndex = prevCodeItemIndex
        currInstructionIndex = prevInstructionIndex
    }
    
    // Stop playback
    public func stop() {
        reset()
        
        error = .none
        DispatchQueue.main.async {
            self.errorChanged.send(.none)
        }

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
        prevCodeItemIndex = currCodeItemIndex
        prevInstructionIndex = currInstructionIndex
        
        // Check if we need to execute timed events.
        for (index, _) in cpu.eventQueue.enumerated().reversed() {
            cpu.eventQueue[index].countdown -= deltaTimeInMs
            if cpu.eventQueue[index].countdown <= 0 {
                currCodeItemIndex = cpu.eventQueue[index].codeItemIndex
                currInstructionIndex = cpu.eventQueue[index].instructionIndex
                execute()
                cpu.eventQueue.remove(at: index)
            }
        }

        // Update
        currCodeItemIndex = 1
        currInstructionIndex = 0
        execute()
        cpuRender.update()
        
        currCodeItemIndex = prevCodeItemIndex
        currInstructionIndex = prevInstructionIndex
    }
    
    // Executes the current code address
    public func execute() {
        while let instruction = getInstruction() {
            let result = cpu.executeInstruction(instruction: instruction, gcp: gcp)

            if result == .nextInstruction {
                currInstructionIndex += 1
            } else
            if result == .stop
            {
                break;
            }
        }
    }
    
    // Execute the current instruction (single step mode)
    public func executeInstruction() {
        if let instruction = getInstruction() {
            _ = cpu.executeInstruction(instruction: instruction, gcp: gcp)
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
    
    // Get the instruction at the given positions
    public func getInstructionAt(codeItemIndex: Int, instructionIndex: Int) -> Instruction? {
        // Check if the currCodeItemIndex is within bounds
        guard codeItemIndex >= 0 && codeItemIndex < data.codeItems.count else {
            return nil
        }

        let codeItem = data.codeItems[currCodeItemIndex]

        // Check if the currInstructionIndex is within bounds for the selected codeItem
        guard instructionIndex >= 0 && instructionIndex < codeItem.codes.count else {
            return nil
        }

        return codeItem.codes[instructionIndex]
    }
    
    func getCodeItem() -> CodeItem? {
        return data.codeItems[currCodeItemIndex]
    }
    
    // Returns the codeItem of a given name
    func getCodeItem(byName name: String) -> CodeItem? {
        return data.codeItems.first { $0.name == name }
    }
    
    // Returns the codeItem of a given name
    func getCodeItemIndex(byItem item: CodeItem) -> Int? {
        return data.codeItems.firstIndex { $0 === item }
    }
    
    // Returns the imageGroupItem of a given name
    func getImageGroupItem(imageGroupName: String) -> ImageGroupItem? {
        return data.imageGroupItems.first { $0.name == imageGroupName }
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
        
        cpu.eventQueue.removeAll()
        
        DispatchQueue.main.async {
            self.stack = []
        
            self.flags.clearFlags()
                
            for i in 0...7 {
                self.registers[i] = ChipCadeData.unsigned16Bit(0)
            }
        }
    }
    
    // Set an active eeror
    func setError(_ error: ChipCadeError) {
        self.error = error
        errorCodeItemIndex = currCodeItemIndex
        errorInstructionIndex = currInstructionIndex
        
        pause()
        errorChanged.send(error)
    }
}
