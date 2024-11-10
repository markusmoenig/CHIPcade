//
//  CPU.swift
//  ChipCade
//
//  Created by Markus Moenig on 2/10/24.
//

import MetalKit

/// Returned by executeInstruction()
public enum ExecuteResult {
    case nextInstruction
    case jumped
    case stop
}

/// Functions which will be called after countdown finishes (set via CALLTM).
public struct TimedEvent {
    var countdown: Int
    
    var codeItemIndex: Int
    var instructionIndex: Int
}

public class CPU {
        
    var game: Game!
    var eventQueue: [TimedEvent] = []

    init() {
    }
    
    public func executeInstruction(instruction: Instruction, gcp: GCP) -> ExecuteResult {
        
        switch instruction.type {
        
        case .add   :  if game.registers[Int(instruction.register1!)].add(other: instruction.value!.resolve(game), flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
        
        case .cmp   :  if game.registers[Int(instruction.register1!)].cmp(other: instruction.value!.resolve(game), flags: game.flags) {
            game.setError(.invalidComparison)
        } else {
            game.lastCMPWasUnsigned = game.registers[Int(instruction.register1!)].isUnsigned()
        }
            
        case .call:
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                let memoryText = game.data.codeItems[game.currCodeItemIndex].name
                let offsetText = String(format: "0x%X", game.currInstructionIndex + 1)
                let string = "\(memoryText) + \(offsetText)"
                game.stack.append(.address(string))
                
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                
                return .jumped
            } else {
                game.setError(.invalidCodeAddress)
            }
            
        case .calltm:
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                // countdown, convert from seconds to milli-seconds
                let countdown = Int(instruction.value!.resolve(game).toFloat32Bit() * 1000)
                let event = TimedEvent(countdown: countdown, codeItemIndex: codeItemIndex, instructionIndex: instructionIndex)
                eventQueue.append(event)
            } else {
                game.setError(.invalidCodeAddress)
            }
            
        case .ret:
            if let address = game.stack.popLast() {
                let string = address.toString()
                let components = string.split(separator: "+")
                let moduleName = String(components[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let hexString = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanedHexString = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString

                if let offset = Int(cleanedHexString, radix: 16) {
                    if let codeItem = game.getCodeItem(byName: moduleName) {
                        if let moduleIndex = game.getCodeItemIndex(byItem: codeItem) {
                            game.currCodeItemIndex = moduleIndex
                            game.currInstructionIndex = offset
                            return .jumped
                        }
                    }
                }
            } else {
                return .stop
            }
        
        case .inc   :  game.registers[Int(instruction.register1!)].inc(flags: game.flags)
        
        case .div   :  if game.registers[Int(instruction.register1!)].div(other: instruction.value!.resolve(game), flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
            
        case .j    :
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return .jumped
            } else {
                game.setError(.invalidCodeAddress)
            }
            
        case .je    : if game.flags.zeroFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return .jumped
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
            
        case .jne   : if !game.flags.zeroFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return .jumped
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
                return .jumped
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
                return .jumped
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
            
        case .jc    : if game.flags.carryFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return .jumped
            } else {
                game.setError(.invalidCodeAddress)
            }
        }
            
        case .jo    : if game.flags.overflowFlag {
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                game.currCodeItemIndex = codeItemIndex
                game.currInstructionIndex = instructionIndex
                return .jumped
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
        
        case .ldi   : game.registers[Int(instruction.register1!)] = instruction.value!.resolve(game)
        
        case .ldresx:
            game.registers[Int(instruction.register1!)] = .unsigned16Bit(UInt16(gcp.draw2D.metalView.frame.size.width))
        
        case .ldresy:
            game.registers[Int(instruction.register1!)] = .unsigned16Bit(UInt16(gcp.draw2D.metalView.frame.size.height))
        
        case .ldspr   :
            let spriteIndex = Int(instruction.register2!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                let register = Int(instruction.register1!)
                switch instruction.memory?.lowercased() {
                 
                case "x":
                    game.registers[register] = .signed16Bit(Int16(gcp.sprites[spriteIndex].position.x))
                    
                case "y":
                    game.registers[register] = .signed16Bit(Int16(gcp.sprites[spriteIndex].position.y))

                case "speed":
                    game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].speed)))
                    
                default:
                    break
                }
                
            } else {
                game.setError(.invalidSpriteIndex)
            }
        case .lyrres:
            let layerIndex = Int(instruction.register1!)
            if layerIndex >= 0 && layerIndex <= 7 {
                let components = instruction.memory!.split(separator: " ")
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
                gcp.addCmd(.lyrvis(layerIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidLayerIndex)
            }
            
        case .mod   :  if game.registers[Int(instruction.register1!)].mod(other: instruction.value!.resolve(game), flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
        
        case .mul   :  if game.registers[Int(instruction.register1!)].mul(other: instruction.value!.resolve(game), flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
            
        case .push  : game.stack.append(.value(instruction.value!.resolve(game)))
        
        case .rand:
            game.registers[Int(instruction.register1!)] = ChipCadeData.random(upTo: instruction.value!.resolve(game))
            
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
            
        case .st:
            if game.setMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!, value: instruction.value!.resolve(game)) {
                game.setError(.invalidMemoryAddress)
            }
            
        case .spracc:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spracc(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprcol:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                let value = instruction.value!.resolve(game).toInt32Bit()
                let sprite = gcp.sprites[spriteIndex]
                game.flags.setZeroFlag(false)
                for toCheck in gcp.sprites {
                    if sprite.layer == toCheck.layer && sprite.index != toCheck.index && toCheck.collisionGroupIndex == value {
                        if sprite.checkCollision(with: toCheck) {
                            game.flags.setZeroFlag(true)
                        }
                    }
                }
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprgrp:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprgrp(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprlyr:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprlyr(spriteIndex: Int(instruction.register1!), value: Int(instruction.register2!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .spract:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spract(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprrot:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprrot(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprx:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                //gcp.addCmd(.sprx(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
                
                // We have to update it here to make sure collisions have up to date data
                game.gcp.sprites[spriteIndex].position.x = CGFloat(instruction.value!.resolve(game).toFloat32Bit())
            } else {
                game.setError(.invalidSpriteIndex)
            }

        case .spry:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                //gcp.addCmd(.spry(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
                
                game.gcp.sprites[spriteIndex].position.y = CGFloat(instruction.value!.resolve(game).toFloat32Bit())
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprspd:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprspd(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprwrp:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprwrp(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprimg:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprimg(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprpri:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprpri(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprmxs:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprmxs(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
      
        case .sprfri:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprfri(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .spranm:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spranm(spriteIndex: Int(instruction.register1!), from: Int(instruction.register2!), to: Int(instruction.register3!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprfps:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprfps(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .spralp:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spralp(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprscl:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprscl(spriteIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sub   :  if game.registers[Int(instruction.register1!)].sub(other: instruction.value!.resolve(game), flags: game.flags) {
            game.setError(.invalidArithmetic)
        }
            
        case .sprstp:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprstp(spriteIndex: Int(instruction.register1!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprhlt:
            let spriteIndex = Int(instruction.register1!)
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprhlt(spriteIndex: Int(instruction.register1!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .fntset:
            let fontName = instruction.memory!.lowercased()
            let fontSize = instruction.value!.resolve(game)

            for f in fonts {
                if f.lowercased() == fontName{
                    gcp.addCmd(.fntset(fontName: fontName, fontSize: fontSize.toFloat32Bit()))
                    return .nextInstruction
                }
            }
            
            game.setError(.unknownFont)
           
        case .txtmem:
            let x = game.registers[0].toFloat32Bit()
            let y = game.registers[1].toFloat32Bit()
            let colorIndex = game.registers[2].toInt32Bit()
            var offset = instruction.memoryOffset!
            if var value = game.getMemoryValue(memoryItemName: instruction.memory!, offset: offset) {
                if !value.isUnicode() {
                    gcp.addCmd(.text(text: value.toString(false), x: x, y: y, colorIndex: colorIndex))
                } else {
                    var text: String = value.toChar()
                    while value.isUnicode() {
                        offset += 1
                        if let val = game.getMemoryValue(memoryItemName: instruction.memory!, offset: offset) {
                            if val.isUnicode() {
                                text += val.toChar()
                            }
                            value = val
                        } else {
                            break;
                        }
                    }                    
                    gcp.addCmd(.text(text: text, x: x, y: y, colorIndex: colorIndex))
                }
            } else {
                game.setError(.invalidMemoryAddress)
            }
                  
        case .txtval:
            let x = game.registers[0].toFloat32Bit()
            let y = game.registers[1].toFloat32Bit()
            let colorIndex = game.registers[2].toInt32Bit()
            gcp.addCmd(.text(text: instruction.value!.resolve(game).toString(false), x: x, y: y, colorIndex: colorIndex))
            
        default: break
        }
        
        return .nextInstruction
    }
    
    func getRegisterValueInt(_ register: UInt8) -> Int {
        Int(game.registers[Int(register)].toFloat32Bit())
    }
    
    func getRegisterValueFloat(_ register: UInt8) -> Float {
        Float(game.registers[Int(register)].toFloat32Bit())
    }
}

