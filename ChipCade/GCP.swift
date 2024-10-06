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
    
    public func setupView(_ metalView: ChipCadeView)
    {
        draw2D.setupView(metalView)
        
        for _ in 0..<7 {
            _ = draw2D.createTexture(width: 100, height: 100)
        }
    }
    
    // Add a cmd
    func addCmd(_ cmd: GCPCmd) {
        self.cmds.append(cmd)
    }
    
    func draw() {
        if cmds.isEmpty { return }
        
        draw2D.syncTexturesToView()
        
        let targetLayer = 1
//        let width = Int(draw2D.metalView.frame.width)
//        let height = Int(draw2D.metalView.frame.height)
        
        draw2D.setTarget(id: targetLayer)
        draw2D.setTexture(id: 0)

        draw2D.encodeStart()
        draw2D.clear(color: float4(0.0, 0.0, 0.0, 0.0))

        for cmd in cmds {
            switch cmd {
            case .rect(let x, let y, let width, let height, let color, let rot) :
                draw2D.currentSampler = draw2D.nearestSampler
                draw2D.startShape(type: .triangle)
                draw2D.drawRect(x, y, width, height, color.simd, -rota)
                draw2D.endShape()
                //draw2D.drawText(position: float2(100, 80), text: "test", size: 30)

            }
        }
        
        rota += 1.0

        draw2D.encodeEnd()

        draw2D.setTarget(id: 0)
        draw2D.setTexture(id: 1)

        draw2D.encodeStart()
        
        //draw2D.currentSampler = draw2D.nearestSampler

//        draw2D.startShape(type: .triangle)
//        draw2D.drawRect(0, 0, Float(width), Float(height))
//        draw2D.endShape()
        
        draw2D.copyTexture()
        
        draw2D.encodeEnd()
        cmds.removeAll()
    }
}

