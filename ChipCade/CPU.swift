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
        case .ldi   : game.registers[Int(instruction.register1!)] = instruction.value!
        case .push  : game.stack.append(instruction.value!)
        case .rect  :
            let x : Float = game.registers[0].toFloat32Bit()
            let y : Float = game.registers[1].toFloat32Bit()
            let width : Float = game.registers[2].toFloat32Bit()
            let height : Float = game.registers[3].toFloat32Bit()
            let index : Int = Int(game.registers[4].toFloat32Bit())

            if index >= 0 && index < game.palette.count {
                let color = game.palette[index]
                let cmd : GCPCmd = .rect(x: x, y: y, width: width, height: height, color: GCPFloat4(simd: color), rot: 0.0)
                gcp.addCmd(cmd)
            }
            
        default: break
        }
    }
}

