//
//  CPU.swift
//  ChipCade
//
//  Created by Markus Moenig on 2/10/24.
//

public class CPU {
        
    var game: Game!
    
    init() {
    }
    
    public func executeInstruction(instruction: Instruction, gcp: GCP) -> Bool {
        
        switch instruction.type {
        case .cmp   :  if game.registers[Int(instruction.register1!)].cmp(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidComparison)
        } else {
            game.lastCMPWasUnsigned = game.registers[Int(instruction.register1!)].isUnsigned()
        }
        case .inc   :  game.registers[Int(instruction.register1!)].inc(flags: game.flags)
        case .je    : if game.flags.zeroFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return false
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
        case .jne   : if !game.flags.zeroFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return false
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
        case .jl    :

        // For unsigned, less than is indicated by the carry flag
        // For signed, check negative and overflow
                    
        let jl = game.lastCMPWasUnsigned ? game.flags.carryFlag : game.flags.negativeFlag != game.flags.overflowFlag
        if jl {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return false
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
        case .jg    :
            
        // For unsigned, greater than is indicated by no carry and not zero
        // For signed, consistent flags and not zero
            
        let jg = game.lastCMPWasUnsigned ? !game.flags.carryFlag && !game.flags.zeroFlag : !game.flags.zeroFlag && game.flags.negativeFlag == game.flags.overflowFlag
        if jg {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return false
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
        case .jc    : if game.flags.carryFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return false
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
        case .jo    : if game.flags.overflowFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return false
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
        case .dec   :  game.registers[Int(instruction.register1!)].dec(flags: game.flags)
        case .ld    :
            if let value = game.getMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!) {
                game.registers[Int(instruction.register1!)] = value
            } else {
                game.setError(.invalidMemoryAddress)
            }
        case .ldi   : game.registers[Int(instruction.register1!)] = instruction.value!
        case .push  : game.stack.append(instruction.value!)
        case .rect  :
            let x : Float = game.registers[0].toFloat32Bit()
            let y : Float = game.registers[1].toFloat32Bit()
            let width : Float = game.registers[2].toFloat32Bit()
            let height : Float = game.registers[3].toFloat32Bit()
            let index : Int = Int(game.registers[4].toFloat32Bit())

            if index >= 0 && index < game.data.palette.count {
                let color = game.data.palette[index]
                let cmd : GCPCmd = .rect(x: x, y: y, width: width, height: height, color: GCPFloat4(simd: color), rot: 0.0)
                gcp.addCmd(cmd)
            }
            
        case .sprset:
            if let spriteItem = game.getImageGroupItem(imageGroupName: instruction.memory!) {
                gcp.addCmd(.sprset(spriteIndex: Int(instruction.register1!), imageGroupName: spriteItem.name))
            } else {
                game.setError(.invalidImageGroup)
            }
            
        case .st    :
            if game.setMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!, value: game.registers[Int(instruction.register1!)]) {
                game.setError(.invalidMemoryAddress)
            }
            
        case .sprvis:
            gcp.addCmd(.sprvis(spriteIndex: Int(instruction.register1!), value: getRegisterValueInt(instruction.register2!)))
            
        case .sprx:
            gcp.addCmd(.sprx(spriteIndex: Int(instruction.register1!), value: getRegisterValueInt(instruction.register2!)))

        case .spry:
            gcp.addCmd(.spry(spriteIndex: Int(instruction.register1!), value: getRegisterValueInt(instruction.register2!)))
            
        default: break
        }
        
        return true
    }

    func getRegisterValueInt(_ register: Int8) -> Int {
        Int(game.registers[Int(register)].toFloat32Bit())
    }
}

