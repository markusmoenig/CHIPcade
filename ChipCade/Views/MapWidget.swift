//
//  MapWidget.swift
//  CHIPcade
//
//  Created by Markus Moenig on 24/11/24.
//

import Foundation
import SwiftUI

import MetalKit
import Combine

public class MapWidget
{
    var screenSize: float2 = .zero
    
    func mouseDown(pos: float2, gridPos: float2, mapItem: MapItem) {
        
    }

    func mouseDragged(pos: float2, gridPos: float2, mapItem: MapItem) {
        
    }
    
    func mouseUp(pos: float2, gridPos: float2, mapItem: MapItem) {
        
    }
    
    func draw(draw2D: MetalDraw2D, mapItem: MapItem, game: Game)
    {
        draw2D.encodeStart(.clear)
//        draw2D.drawBox(position: float2(10, 10), size: float2(200, 100), rounding: 10.0, borderSize: 4, onion: 0.0, fillColor: float4(1, 0.5, 0.2, 1), borderColor: float4(0.5, 1, 0.2, 1))
        draw2D.drawGrid(offset: mapItem.offset, gridSize: mapItem.gridSize, backgroundColor: float4(1, 0, 0, 1))
        draw2D.encodeEnd()
    }
    
    func colorToFloat4(_ color: Color) -> simd_float4 {
        #if os(iOS)
        // iOS uses UIColor
        let uiColor = UIColor(color) // Try to initialize directly from SwiftUI Color
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Ensure color is in RGB color space and extract the components
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        alpha = 1.0
        
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
