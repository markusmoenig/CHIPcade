//
//  CPU.swift
//  ChipCade
//
//  Created by Markus Moenig on 2/10/24.
//

public class CPU {
        
    init() {
    }
    
    public func executeInstruction(instruction: Instruction, game: Game, gcp: GCP) {
        
        switch instruction.type {
        case .inc   :  game.registers[Int(instruction.register1!)].inc(flags: game.flags)
        case .dec   :  game.registers[Int(instruction.register1!)].dec(flags: game.flags)
        case .ld    :
            if let value = game.getMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!) {
                game.registers[Int(instruction.register1!)] = value
            } else {
                // Error: Invalid Memory Address
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
            if let spriteItem = game.getSpriteItem(spriteName: instruction.memory!) {
                //print("got \(instruction.memory)")
                gcp.addCmd(.sprset(spriteIndex: Int(instruction.register1!), imageGroupName: spriteItem.name))
            } else {
                // Error: Invalid Sprite
            }
        case .st    :
            if game.setMemoryValue(memoryItemName: instruction.memory!, offset: instruction.memoryOffset!, value: instruction.value!) {
                // Error: Invalid Memory Address
            }
        default: break
        }
    }
}

