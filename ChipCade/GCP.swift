//
//  GCP.swift
//  ChipCade
//
//  Created by Markus Moenig on 2/10/24.
//

public enum GCPCmd  {
    case rect(x: Float, y: Float, width: Float, height: Float, color: GCPFloat4, rot: Float)
}

public class GCP {
    
    var cmds: [GCPCmd] = []
    
    init() {
    }
    
    // Add a cmd
    func addCmd(_ cmd: GCPCmd) {
        self.cmds.append(cmd)
    }
    
    func draw(draw2D: MetalDraw2D) {
        if cmds.isEmpty { return }
        
        draw2D.encodeStart()
        //draw2D.clear(color: float4(0.0, 0.0, 0.0, 0.0))

        for cmd in cmds {
            switch cmd {
            case .rect(let x, let y, let width, let height, let color, let rot) :
                draw2D.startShape(type: .triangle)
                draw2D.drawRect(x, y, width, height, color.simd, rot)
                draw2D.endShape()
            }
        }
        
        draw2D.encodeEnd()
        cmds.removeAll()
    }
}

