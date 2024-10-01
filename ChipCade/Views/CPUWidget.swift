//
//  CPUWidget.swift
//  ChipCade
//
//  Created by Markus Moenig on 1/10/24.
//

import Foundation

import MetalKit
import Combine

public class CPUWidget    : ObservableObject
{
    init()
    {
    }

    func draw(draw2D: MetalDraw2D)
    {
        draw2D.encodeStart()
        draw2D.Clear(color: float4(0, 0, 0, 0))
//        draw2D.startShape(type: .triangle)
//        draw2D.drawRect(Rectangle(x: 10, y: 40, width: 200, height: 200), float4(1, 0, 1, 1), 0.0)
//        draw2D.endShape()
//        draw2D.drawText(position: float2(100, 100), text: "CHIPCADE", size: 30)
        draw2D.encodeEnd()
    }
}
