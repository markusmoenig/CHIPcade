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
    case breakpoint
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
        
        // Arithmetic. Source types get cast to destination types automatically.
            
        case .add:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                if game.registers[registerIndex].add(other: instruction.value!.resolve(game).cast(to: game.registers[registerIndex]), flags: game.flags) {
                    game.setError(.invalidArithmetic)
                }
            } else {
                game.setError(.invalidRegister)
            }
        
        case .sub:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                if game.registers[registerIndex].sub(other: instruction.value!.resolve(game).cast(to: game.registers[registerIndex]), flags: game.flags) {
                    game.setError(.invalidArithmetic)
                }
            } else {
                game.setError(.invalidRegister)
            }
            
        case .inc:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                game.registers[registerIndex].inc(flags: game.flags)
            } else {
                game.setError(.invalidRegister)
            }
            
        case .dec:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                game.registers[registerIndex].dec(flags: game.flags)
            } else {
                game.setError(.invalidRegister)
            }
        
        case .div:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                if game.registers[registerIndex].div(other: instruction.value!.resolve(game).cast(to: game.registers[registerIndex]), flags: game.flags) {
                    game.setError(.invalidArithmetic)
                }
            } else {
                game.setError(.invalidRegister)
            }
        
        case .mod:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                if game.registers[Int(instruction.register1!)].mod(other: instruction.value!.resolve(game).cast(to: game.registers[registerIndex]), flags: game.flags) {
                    game.setError(.invalidArithmetic)
                }
            } else {
                game.setError(.invalidRegister)
            }
        
        case .mul:
                let registerIndex = Int(instruction.register1!)
                if registerIndex >= 0 && registerIndex <= 7 {
                    if game.registers[registerIndex].mul(other: instruction.value!.resolve(game).cast(to: game.registers[registerIndex]), flags: game.flags) {
                        game.setError(.invalidArithmetic)
                    }
                } else {
                    game.setError(.invalidRegister)
                }

        case .cos:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                let value = instruction.value!.resolve(game).toFloat32Bit()
                game.registers[registerIndex] = .float16Bit(ChipCadeData.float32ToFloat16(cos(value)))
            } else {
                game.setError(.invalidRegister)
            }
            
        case .sin:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 7 {
                let value = instruction.value!.resolve(game).toFloat32Bit()
                game.registers[registerIndex] = .float16Bit(ChipCadeData.float32ToFloat16(sin(value)))
            } else {
                game.setError(.invalidRegister)
            }
            
        case .cmp:
            let registerIndex = Int(instruction.register1!)
            if registerIndex >= 0 && registerIndex <= 11 {
                
                if registerIndex == 8 {
                    // Special case: For key codes we iterate over all pressed keys
                    let value = instruction.value!.resolve(game).toFloat32Bit()
                    var foundKey: Bool = false
                    for key in game.gcp.draw2D.metalView.keysDown {
                        if key == value {
                            foundKey = true
                            break
                        }
                    }
                    game.flags.setZeroFlag(foundKey)
                    game.flags.setCarryFlag(false)
                    game.flags.setOverflowFlag(false)
                    game.flags.setNegativeFlag(false)
                } else
                if game.registers[registerIndex].cmp(other: instruction.value!.resolve(game).cast(to: game.registers[registerIndex]), flags: game.flags) {
                    game.setError(.invalidComparison)
                } else {
                    game.lastCMPWasUnsigned = game.registers[Int(instruction.register1!)].isUnsigned()
                }
            } else {
                game.setError(.invalidRegister)
            }
            
        //
            
        case .call:
            if let (codeItemIndex, instructionIndex) = game.data.getCodeAddress(name: instruction.memory!, currentCodeIndex: game.currCodeItemIndex) {
                let memoryText = game.currCodeItemIndex == MathLibraryIndex ? "Math" : game.data.codeItems[game.currCodeItemIndex].name
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
                    
        case .ld    :
            if let value = game.getMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!) {
                let register = Int(instruction.register1!)
                if register <= 11 {
                    game.registers[register] = value
                } else {
                    game.setError(.invalidRegister)
                }
            } else {
                game.setError(.invalidMemoryAddress)
            }
        
        case .ldi   :
            let register = Int(instruction.register1!)
            if register <= 11 {
                if register == 8 {
                    // If the current keyCode gets replaced, remove it from keysDown as well
                    game.gcp.draw2D.metalView.keysDown.removeAll{$0 == game.registers[register].toFloat32Bit() }
                }
                game.registers[register] = instruction.value!.resolve(game)
            } else {
                game.setError(.invalidRegister)
            }
        
        case .ldresx:
            let register = Int(instruction.register1!)
            if register <= 11 {
                game.registers[Int(instruction.register1!)] = .unsigned16Bit(UInt16(gcp.draw2D.metalView.frame.size.width))
            } else {
                game.setError(.invalidRegister)
            }
        
        case .ldresy:
            let register = Int(instruction.register1!)
            if register <= 11 {
                game.registers[Int(instruction.register1!)] = .unsigned16Bit(UInt16(gcp.draw2D.metalView.frame.size.height))
            } else {
                game.setError(.invalidRegister)
            }
            
        case .ldspr   :
            var spriteIndex = Int(instruction.register2!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                let register = Int(instruction.register1!)
                if register <= 11 {
                    switch instruction.memory?.lowercased() {
                        
                    case "x":
                        game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].position.x)))
                        
                    case "y":
                        game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].position.y)))
                        
                    case "width":
                        game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].size.width * gcp.sprites[spriteIndex].scale)))
                        
                    case "height":
                        game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].size.height * gcp.sprites[spriteIndex].scale)))
                        
                    case "rotation":
                        game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].rotation)))

                    case "speed":
                        game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(Float(gcp.sprites[spriteIndex].speed)))
                        
                    default:
                        break
                    }
                } else {
                    game.setError(.invalidRegister)
                }
            } else {
                game.setError(.invalidSpriteIndex)
            }
        case .lyrres:
            var layerIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if layerIndex >= 0 && layerIndex <= 7 {
                    layerIndex = game.registers[layerIndex].toInt32Bit()
                } else {
                    game.setError(.invalidLayerIndex)
                }
            }
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
            var layerIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if layerIndex >= 0 && layerIndex <= 7 {
                    layerIndex = game.registers[layerIndex].toInt32Bit()
                } else {
                    game.setError(.invalidLayerIndex)
                }
            }
            if layerIndex >= 0 && layerIndex <= 7 {
                gcp.addCmd(.lyrvis(layerIndex: Int(instruction.register1!), value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidLayerIndex)
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
                var spriteIndex = Int(instruction.register1!)
                if instruction.resolveObject == true {
                    if spriteIndex >= 0 && spriteIndex <= 7 {
                        spriteIndex = game.registers[spriteIndex].toInt32Bit()
                    } else {
                        game.setError(.invalidSpriteIndex)
                    }
                }
                gcp.addCmd(.sprset(spriteIndex: spriteIndex, imageGroupName: spriteItem.name))
            } else {
                game.setError(.invalidImageGroup)
            }
            
        case .st:
            if game.setMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!, value: instruction.value!.resolve(game)) {
                game.setError(.invalidMemoryAddress)
            }
            
        case .spracc:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spracc(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprcol:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
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
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprgrp(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprlyr:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprlyr(spriteIndex: spriteIndex, value: Int(instruction.register2!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .spract:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spract(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprroo:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprroo(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprrot:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprrot(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprx:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                //gcp.addCmd(.sprx(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
                
                // We have to update it here to make sure collisions have up to date data
                game.gcp.sprites[spriteIndex].position.x = CGFloat(instruction.value!.resolve(game).toFloat32Bit())
            } else {
                game.setError(.invalidSpriteIndex)
            }

        case .spry:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                //gcp.addCmd(.spry(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
                
                game.gcp.sprites[spriteIndex].position.y = CGFloat(instruction.value!.resolve(game).toFloat32Bit())
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprspd:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprspd(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprwrp:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprwrp(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprimg:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprimg(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprpri:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprpri(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprmxs:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprmxs(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
      
        case .sprfri:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprfri(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .spranm:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spranm(spriteIndex: spriteIndex, from: Int(instruction.register2!), to: Int(instruction.register3!)))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprfps:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprfps(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toInt32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .spralp:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.spralp(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprscl:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprscl(spriteIndex: spriteIndex, value: instruction.value!.resolve(game).toFloat32Bit()))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprstp:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprstp(spriteIndex: spriteIndex))
            } else {
                game.setError(.invalidSpriteIndex)
            }
            
        case .sprhlt:
            var spriteIndex = Int(instruction.register1!)
            if instruction.resolveObject == true {
                if spriteIndex >= 0 && spriteIndex <= 7 {
                    spriteIndex = game.registers[spriteIndex].toInt32Bit()
                } else {
                    game.setError(.invalidSpriteIndex)
                }
            }
            if spriteIndex >= 0 && spriteIndex <= 255 {
                gcp.addCmd(.sprhlt(spriteIndex: spriteIndex))
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
            
        case .brkpt:
            if game.state == .running {
                game.state = .paused
                game.gcp.draw2D.metalView.enableSetNeedsDisplay = true
                game.gcp.draw2D.metalView.isPaused = true
                game.breaked = true
                game.stepped = true
                game.errorChanged.send(.none)
                game.breakpoint.send()
                return .breakpoint
            }
        
        case .time:
            let register = Int(instruction.register1!)
            if register >= 0 && register <= 7 {
                game.registers[register] = .float16Bit(ChipCadeData.float32ToFloat16(game.elapsedTime))
            } else {
                game.setError(.invalidRegister)
            }

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

