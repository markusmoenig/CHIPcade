//
//  CPUWidget.swift
//  ChipCade
//
//  Created by Markus Moenig on 1/10/24.
//

import Foundation
import SwiftUI

import MetalKit
import Combine

public class CPUWidget    : ObservableObject
{
    init()
    {
    }

    func draw(draw2D: MetalDraw2D, game: Game)
    {
        draw2D.encodeStart()
        draw2D.clear(color: float4(0, 0, 0, 0))
        
        let width = Float(draw2D.metalView.frame.width)
        //let height = Float(draw2D.metalView.frame.height)

        let gX = (width - 640) / 2
        
        let prim = colorToFloat4(Color.primary)
        let sec = colorToFloat4(Color.secondary)
        let red = colorToFloat4(Color.red)
        let green = colorToFloat4(Color.green)

        var dest : Int8? = nil
        var source : [Int8] = []
        
        draw2D.drawText(position: float2(10, 180), text: "\(game.flags.displayFlags())", size: 14, color: prim)
        
        //draw2D.drawText(position: float2(160, 180), text: "R8: \(game.keyASCIICode) R9: \(game.touchState) R10: \(game.touchX) R11: \(game.touchY)", size: 14, color: prim)
        func paddedString<T>(_ value: T, width: Int, fillWith: Character = "0") -> String {
            let stringValue = "\(value)"
            let padding = max(0, width - stringValue.count)
            return String(repeating: fillWith, count: padding) + stringValue
        }

        let formattedInputRegisters = "R8: \(paddedString(game.keyASCIICode, width: 1)) R9: \(paddedString(game.touchState, width: 1)) R10: \(paddedString(game.touchX, width: 6)) R11: \(paddedString(game.touchY, width: 6))"
        draw2D.drawText(position: float2(160, 180), text: formattedInputRegisters, size: 14, color: prim)

        if let instruction = game.getInstruction() {
            //draw2D.drawText(position: float2(100, 80), text: instruction.format(), size: 30)
            //draw2D.drawText(position: float2(310, 180), text: "\(instruction.toString()): \(instruction.description())", size: 14, color: prim)
            let regs = instruction.registers()
            dest = regs.0
            source = regs.1
        }
        

        if game.selectionState == .code {
            
            let reg_x : Float = gX + 20, reg_y : Float = 15, reg_width : Float = 75
            //let pPL : Float = 22.0
            
            for i in 0..<8 {
                var color = prim
                if let dest = dest {
                    if dest == i {
                        color = red
                    }
                }
                if source.contains(Int8(i)) {
                    color = green
                }
                
                draw2D.drawText(position: float2(reg_x + Float(i) * reg_width, reg_y ), text: "R\(i)", size: 15, color: color)
                draw2D.drawText(position: float2(reg_x + Float(i) * reg_width + 20, reg_y), text: "\(game.registers[i].toString())", size: 15, color: sec)
            }
        }
        
        draw2D.encodeEnd()
    }
    
    func colorToFloat4(_ color: Color) -> simd_float4 {
        #if os(iOS)
        // iOS uses UIColor
        let uiColor = UIColor(color)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        #elseif os(macOS)
        // macOS uses NSColor, convert it to sRGB space before extracting components
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white // Fallback to white if conversion fails
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return simd_float4(Float(red), Float(green), Float(blue), Float(alpha))
    }
}
