//
//  Game.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import Combine
import SwiftUI

let MathLibraryIndex : Int = 1000

public enum GameState {
    case running
    case paused
}

public enum EditorMode {
    case code
    case note
    case skin
    case mathLibrary
    case chipReference
}

public class Game : ObservableObject
{
    static var shared = Game()
    
    let errorChanged = PassthroughSubject<ChipCadeError, Never>()
    let codeTextChanged = PassthroughSubject<String, Never>()
    let codeLineChanged = PassthroughSubject<Int, Never>()
    let skinTextChanged = PassthroughSubject<(), Never>()
    let breakpoint = PassthroughSubject<(), Never>()

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

    var mapRender = MetalDraw2D();
    var mapWidget = MapWidget()

    var gcp = GCP()
    var cpu = CPU()

    var error = ChipCadeError.none
    var errorCodeItemIndex = 0
    var errorInstructionIndex = 0
    var errorInstructionType: InstructionType? = nil

    /// Time between updates
    let deltaTimeInMs: Int = Int((1.0 / 60.0) * 1000.0)
    
    /// Elapsed Time
    var elapsedTime: Float = 0.0

    // Game State
    var state = GameState.paused

    // Indicates if the last CMP was unsigned. Needed for later conditional flag evaluation.
    var lastCMPWasUnsigned: Bool = false
    
    // Ace editor instance
    var scriptEditor: ScriptEditor? = nil
    
    // The skin compiler & drawer
    var skin = Skin()
    
    // The Math Library
    var mathLib: [Instruction] = []
    var mathSource: String = ""
    
    // Chip Reference
    var chipRef: String = ""
    
    // Current line numbers
    var noteLine: Int = 0
    var skinLine: Int = 0
    var mathLibLine: Int = 0
    var chipRefLine: Int = 0
    
    // We are currently editing a skin
    var editorMode : EditorMode = .code
    
    // Did we just step ?
    var stepped: Bool = false
    
    // Did execution stop via a brkpt ?
    var breaked: Bool = false
    
    // Current map index (if any)
    var currMapIndex: Int? = nil
    
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
    
    /// Load the default skin
    public func loadDefaultSkin() {
        // Compile Standard Math Library
        if let path = Bundle.main.path(forResource: "skin_default", ofType: "") {
            do {
                data.skin = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                print("Failed to read skin_default: \(error.localizedDescription)")
            }
        }
    }
    
    /// Compile Math Library
    public func compileStandardModules() {
        
        // Compile Standard Math Library
        if let path = Bundle.main.path(forResource: "MathLib", ofType: "") {
            do {
                mathSource = try String(contentsOfFile: path, encoding: .utf8)
                let errorLine = compile(string: mathSource, instructions: &mathLib)
                if let errorLine = errorLine {
                    print("Error in MathLib at \(String(describing: errorLine))")
                }
            } catch {
                print("Failed to read MathLib: \(error.localizedDescription)")
            }
        }
        
        // Load Chip Reference
        if let path = Bundle.main.path(forResource: "ChipRef", ofType: "") {
            do {
                chipRef = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                print("Failed to read ChipRef: \(error.localizedDescription)")
            }
        }
    }
    
    // Executes init, if initOnly is set just updates the display for preview, otherwise starts playback.
    public func play(initOnly: Bool = false) {
        if !breaked {
            reset()
            
            prevCodeItemIndex = currCodeItemIndex
            prevInstructionIndex = currInstructionIndex
            
            currCodeItemIndex = 0
            currInstructionIndex = 0
            
            gcp.setupGameData(gameData: data)
            
            error = .none
            state = .running
            
            if !initOnly {
                gcp.draw2D.metalView.enableSetNeedsDisplay = false
                gcp.draw2D.metalView.isPaused = false
            }
            
            // init
            let result = execute()
            
            if result != .breakpoint {
                currCodeItemIndex = prevCodeItemIndex
                currInstructionIndex = prevInstructionIndex
            }
            
            if initOnly {
                reset()
                gcp.draw2D.update()
                cpuRender.update()
            }
            
            elapsedTime = 0
        } else {
            state = .running
            gcp.draw2D.metalView.enableSetNeedsDisplay = false
            gcp.draw2D.metalView.isPaused = false
        }
        
        breaked = false
    }
    
    // Stop playback
    public func stop() {
        reset()
        
        breaked = false
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
        elapsedTime += 1.0 / 60.0

        prevCodeItemIndex = currCodeItemIndex
        prevInstructionIndex = currInstructionIndex
        
        // Check if we need to execute timed events.
        for (index, _) in cpu.eventQueue.enumerated().reversed() {
            cpu.eventQueue[index].countdown -= deltaTimeInMs
            if cpu.eventQueue[index].countdown <= 0 {
                currCodeItemIndex = cpu.eventQueue[index].codeItemIndex
                currInstructionIndex = cpu.eventQueue[index].instructionIndex
                _ = execute()
                cpu.eventQueue.remove(at: index)
            }
        }

        // Update
        currCodeItemIndex = 1
        currInstructionIndex = 0
        let result = execute()
        cpuRender.update()
        
        if result != .breakpoint {
            currCodeItemIndex = prevCodeItemIndex
            currInstructionIndex = prevInstructionIndex
        }
    }
    
    // Execute a single instruction
    public func step() {
        if let instruction = getInstruction() {
            let result = cpu.executeInstruction(instruction: instruction, gcp: gcp)

            if result == .nextInstruction {
                currInstructionIndex += 1
            }
        }
        cpuRender.update()
        stepped = true
        errorChanged.send(.none)
    }
    
    // Executes the current code address
    public func execute() -> ExecuteResult {
        var result : ExecuteResult = .stop
        while let instruction = getInstruction() {
            result = cpu.executeInstruction(instruction: instruction, gcp: gcp)

            if result == .nextInstruction {
                currInstructionIndex += 1
            } else
            if result == .stop {
                break;
            } else
            if result == .breakpoint {
                currInstructionIndex += 1
                break;
            }
        }
        return result
    }
    
    /// Sync the editor to the current code position, mainly used for stepping
    public func syncEditor() {
        // Check for Math Library
        if currCodeItemIndex == MathLibraryIndex {
            scriptEditor?.setSessionValue("MainSession", mathSource, currInstructionIndex + 1)
        } else {
            // Check if the currCodeItemIndex is within bounds
            guard currCodeItemIndex >= 0 && currCodeItemIndex < data.codeItems.count else {
                return
            }

            let codeItem = data.codeItems[currCodeItemIndex]
            scriptEditor?.setSessionValue("MainSession", codeItem.source, currInstructionIndex + 1)
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
        
        // Check for Math Library
        if currCodeItemIndex == MathLibraryIndex {
            guard currInstructionIndex >= 0 && currInstructionIndex < mathLib.count else {
                return nil
            }
            return mathLib[currInstructionIndex]
        }
        
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
    
    // Returns the index of the given CodeItem
    func getCodeItemIndex(byItem item: CodeItem) -> Int? {
        return data.codeItems.firstIndex { $0 === item }
    }
    
    // Returns the imageGroupItem of a given name
    func getImageGroupItem(imageGroupName: String) -> ImageGroupItem? {
        return data.imageGroupItems.first { $0.name == imageGroupName }
    }
    
    // Returns the index of the given MapItem
    func getMapItemIndex(byItem item: MapItem) -> Int? {
        return data.mapItems.firstIndex { $0 === item }
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
    
    public func drawMap()
    {
        if let mapIndex = currMapIndex {
            mapWidget.draw(draw2D: mapRender, mapItem: data.mapItems[mapIndex], game: self)
        }
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
    
    // Error
    func compile(string: String, instructions: inout [Instruction]) -> Int? {
        let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
        
        var errorLine : Int? = nil
        
        for (index, line) in lines.enumerated() {
            // If line is empty, treat it as NOP
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                instructions.append(Instruction(.nop))
                continue
            }
            
            // Check if the string is a comment
            if let comment = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).last,
                line.trimmingCharacters(in: .whitespaces).starts(with: "#") {
                let instruction = Instruction(.comnt)
                instruction.memory = String(comment.trimmingCharacters(in: .whitespaces))
                instructions.append(instruction)
                continue
            }
            
            // Check if the line is a tag (ends with ':')
            if line.trimmingCharacters(in: .whitespaces).hasSuffix(":") {
                let tagName = String(line.trimmingCharacters(in: .whitespaces).dropLast()) // Remove the colon
                
                // Validate the tag name
                if tagName.isEmpty || tagName.contains(" ") || tagName.first?.isNumber == true {
                    errorLine = index
                    break
                }
                
                // Create the tag instruction
                let instruction = Instruction(.tag)
                instruction.memory = tagName
                //print(instruction.format())
                instructions.append(instruction)
                continue
            }
            
            if let instruction = Instruction.fromString(String(line)) {
                //print(instruction.format())
                instructions.append(instruction)
            } else {
                //print("Error: \(String(line))")
                errorLine = index
                break;
            }
        }
        
        return errorLine
    }
}
