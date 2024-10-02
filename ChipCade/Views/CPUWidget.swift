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
        
        let prim = colorToFloat4(Color.primary)
        let sec = colorToFloat4(Color.secondary)
        
        if game.selectionState == .code {
            
            let reg_x : Float = 10, reg_y : Float = 20, reg_width : Float = 60
            
            for i in 0..<8 {
                draw2D.drawText(position: float2(reg_x + Float(i) * reg_width, reg_y), text: "R\(i)", size: 12, color: prim)
                draw2D.drawText(position: float2(reg_x + Float(i) * reg_width + 16, reg_y), text: "\(game.registers[i].toString())", size: 12, color: sec)
            }
            
            if let instruction = game.getInstruction() {
                draw2D.drawText(position: float2(100, 100), text: instruction.format(), size: 30)
                draw2D.drawText(position: float2(20, 180), text: instruction.description(), size: 14, color: prim)
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
