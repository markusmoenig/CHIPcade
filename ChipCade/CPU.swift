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
        
        case .add   :  if game.registers[Int(instruction.register1!)].add(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
        
        case .cmp   :  if game.registers[Int(instruction.register1!)].cmp(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidComparison)
        } else {
            game.lastCMPWasUnsigned = game.registers[Int(instruction.register1!)].isUnsigned()
        }
        
        case .inc   :  game.registers[Int(instruction.register1!)].inc(flags: game.flags)
        
        case .div   :  if game.registers[Int(instruction.register1!)].div(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
            
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
        
        case .ldresx:
            game.registers[Int(instruction.register1!)] = .unsigned16Bit(UInt16(gcp.draw2D.metalView.frame.size.width))
        
        case .ldresy:
            game.registers[Int(instruction.register1!)] = .unsigned16Bit(UInt16(gcp.draw2D.metalView.frame.size.height))
        
        case .lyrres:
            let layerIndex = Int(instruction.register1!)
            if layerIndex >= 0 && layerIndex <= 7 {
                let components = instruction.memory!.split(separator: "x")
                if components.count == 2 {
                    let width = Int(components[0])
                    let height = Int(components[1])
                    if let width = width, let height = height {
                        if width > 0 && width < 10000 && height > 0 && height < 10000 {
                            gcp.addCmd(.lyrres(layerIndex: Int(instruction.register1!), width: width, height: height))
                        } else {
                            game.setError(.invalidResolution)
                        }
                    } else {
                        game.setError(.invalidResolution)
                    }
                } else {
                    game.setError(.invalidResolution)
                }
            } else {
                game.setError(.invalidLayerIndex)
            }
            
        case .lyrvis:
            let layerIndex = Int(instruction.register1!)
            if layerIndex >= 0 && layerIndex <= 7 {
                gcp.addCmd(.lyrvis(layerIndex: Int(instruction.register1!), value: Int(instruction.register2!)))
            } else {
                game.setError(.invalidLayerIndex)
            }
            
        case .mod   :  if game.registers[Int(instruction.register1!)].mod(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
        
        case .mul   :  if game.registers[Int(instruction.register1!)].mul(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
            
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
            
        case .sprlyr:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprlyr(spriteIndex: Int(instruction.register1!), value: Int(instruction.register2!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprvis:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprvis(spriteIndex: Int(instruction.register1!), value: Int(instruction.register2!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprrot:
            gcp.addCmd(.sprrot(spriteIndex: Int(instruction.register1!), value: getRegisterValueInt(instruction.register2!)))
            
        case .sprx:
            gcp.addCmd(.sprx(spriteIndex: Int(instruction.register1!), value: getRegisterValueInt(instruction.register2!)))

        case .spry:
            gcp.addCmd(.spry(spriteIndex: Int(instruction.register1!), value: getRegisterValueInt(instruction.register2!)))
            
        case .sprspd:
            gcp.addCmd(.sprspd(spriteIndex: Int(instruction.register1!), value: getRegisterValueFloat(instruction.register2!)))
            
        case .sub   :  if game.registers[Int(instruction.register1!)].sub(other: game.registers[Int(instruction.register2!)], flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
            
        default: break
        }
        
        return true
    }

    func getRegisterValueInt(_ register: Int8) -> Int {
        Int(game.registers[Int(register)].toFloat32Bit())
    }
    
    func getRegisterValueFloat(_ register: Int8) -> Float {
        Float(game.registers[Int(register)].toFloat32Bit())
    }
}

