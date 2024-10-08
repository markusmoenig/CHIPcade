//
//  CodeItem.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Combine
import SwiftUI

class CodeItem : ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID
    
    @Published var codes: [Instruction]
    @Published var name: String {
        willSet {
            objectWillChange.send()  // Trigger update when the name is set
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, codes, name, currInstr
    }
    
    init(name: String) {
        id = UUID()
        self.name = name
        codes = [Instruction(.nop)]
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        codes = try container.decode([Instruction].self, forKey: .codes)
        name = try container.decode(String.self, forKey: .name)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(codes, forKey: .codes)
        try container.encode(name, forKey: .name)
    }
    
    // Rename the code item with undo/redo support
    func rename(to newName: String, using undoManager: UndoManager?, setSelectedItem: @escaping (CodeItem?) -> Void) {
        let previousName = self.name
        self.name = newName

        // Trigger a UI update by setting the selected item
        setSelectedItem(self)

        // Register undo action to restore the previous name
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            targetSelf.name = previousName
            setSelectedItem(targetSelf)  // Set as selected again after undo

            // Register redo action to rename the item again
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.rename(to: newName, using: undoManager, setSelectedItem: setSelectedItem)
            }
        }
        undoManager?.setActionName("Rename Code Item")
    }
    
    // Read a value at a specific index
    func readCode(at index: Int) -> Instruction {
        return codes[index]
    }
    
    // Write a value at a specific index
    func writeCode(at index: Int, value: Instruction, using undoManager: UndoManager?) {
        let previousInstruction = codes[index]
        codes[index] = value
        
        undoManager?.registerUndo(withTarget: self) { [previousInstruction] targetSelf in
            targetSelf.codes[index] = previousInstruction
            
            // Register redo action to restore the new instruction
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.codes[index] = value
            }
        }
        
        undoManager?.setActionName("Write Code")
    }
    // Duplicate an instruction at a given index
    func duplicate(at index: Int, using undoManager: UndoManager?) {
        guard index >= 0 && index < codes.count else { return }
        
        let clonedInstruction = codes[index].clone()
        codes.insert(clonedInstruction, at: index + 1)
        
        undoManager?.registerUndo(withTarget: self) { [clonedInstruction] targetSelf in
            targetSelf.codes.remove(at: index + 1)
            
            // Register redo action to duplicate the instruction again
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.codes.insert(clonedInstruction, at: index + 1)
            }
        }
        
        undoManager?.setActionName("Duplicate Instruction")
    }
    
    // Delete an instruction at a given index
    func delete(at index: Int, using undoManager: UndoManager?) {
        guard index >= 0 && index < codes.count else { return }
        
        let deletedInstruction = codes[index]
        codes.remove(at: index)
        
        undoManager?.registerUndo(withTarget: self) { [deletedInstruction] targetSelf in
            targetSelf.codes.insert(deletedInstruction, at: index)
            
            // Register redo action to delete the instruction again
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.codes.remove(at: index)
            }
        }
        
        undoManager?.setActionName("Delete Instruction")
    }
    
    // Insert a new instruction before a given index
    func insertBefore(at index: Int, instruction: Instruction, using undoManager: UndoManager?) {
        // Insert the new instruction
        if codes.isEmpty {
            codes.insert(instruction, at: 0)
        } else if index >= 0 && index <= codes.count {
            codes.insert(instruction, at: index)
        }
        
        undoManager?.registerUndo(withTarget: self) { [instruction] targetSelf in
            targetSelf.codes.remove(at: index)
            
            // Register redo action to reinsert the instruction at the same position
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.codes.insert(instruction, at: index)
            }
        }
        
        undoManager?.setActionName("Insert Instruction Before")
    }
    
    // Insert a new instruction after a given index
    func insertAfter(at index: Int, instruction: Instruction, using undoManager: UndoManager?) {
        // Insert the new instruction
        if codes.isEmpty {
            codes.insert(instruction, at: 0)
        } else if index >= 0 && index < codes.count {
            codes.insert(instruction, at: index + 1)
        }
        
        undoManager?.registerUndo(withTarget: self) { [instruction] targetSelf in
            targetSelf.codes.remove(at: index + 1)
            
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                // Redo the insertion exactly where it was
                redoSelf.codes.insert(instruction, at: index + 1)
            }
        }
        
        undoManager?.setActionName("Insert Instruction After")
    }
    
    // An instruction at the given index is about to change
    func aboutToChange(using undoManager: UndoManager?, newInstruction: Instruction, at index: Int, text: String = "Instruction Changed") {
        let previousInstruction = codes[index]
        
        codes[index] = newInstruction
        Game.shared.cpuRender.update()
        
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            targetSelf.aboutToChange(using: undoManager, newInstruction: previousInstruction, at: index, text: text)
        }
        
        undoManager?.setActionName(text)
    }
    
    static func == (lhs: CodeItem, rhs: CodeItem) -> Bool {
        return lhs.id == rhs.id
    }
}
