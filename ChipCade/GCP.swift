//
//  GCP.swift
//  ChipCade
//
//  Created by Markus Moenig on 2/10/24.
//

public enum GCPCmd  {
    case rect(x: Float, y: Float, width: Float, height: Float, color: GCPFloat4, rot: Float)
}

var rota : Float = 0.0

public class GCP {
    
    var cmds: [GCPCmd] = []
    
    var draw2D = MetalDraw2D();

    init() {
    }
    
    // Add a cmd
    func addCmd(_ cmd: GCPCmd) {
        self.cmds.append(cmd)
    }
    
    func draw() {
        if cmds.isEmpty { return }
        
        draw2D.encodeStart()
        //draw2D.clear(color: float4(0.0, 0.0, 0.0, 0.0))

        for cmd in cmds {
            switch cmd {
            case .rect(let x, let y, let width, let height, let color, let rot) :
                draw2D.startShape(type: .triangle)
                draw2D.drawRect(x, y, width, height, color.simd, -rota)
                draw2D.endShape()
            }
        }
        
        rota += 1.0
        
        draw2D.encodeEnd()
        cmds.removeAll()
    }
}

