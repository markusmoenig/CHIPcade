//
//  GCP.swift
//  ChipCade
//
//  Created by Markus Moenig on 2/10/24.
//

import MetalKit

public enum GCPCmd  {
    case rect(x: Float, y: Float, width: Float, height: Float, color: GCPFloat4, rot: Float)
    case sprset(spriteIndex: Int, imageGroupName: String)
}

var rota : Float = 0.0

public class GCP {
    
    var cmds: [GCPCmd] = []
    var draw2D = MetalDraw2D();
    
    var imageGroups: [ImageGroup] = []
    var sprites: [Sprite] = []
    
    init() {
    }
    
    public func setupView(_ metalView: ChipCadeView)
    {
        draw2D.setupView(metalView)
        
        for _ in 0..<8 {
            _ = draw2D.createTexture(width: 100, height: 100)
        }
    }
    
    // Add a cmd
    func addCmd(_ cmd: GCPCmd) {
        self.cmds.append(cmd)
    }
    
    // Initialize game related data, like textures.
    func setupGameData(gameData: GameData) {
        imageGroups = []
        
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : false, .SRGB : false]

        // Load the images as textures
        for sprite in gameData.spriteItems {
            let group = ImageGroup(name: sprite.name)
            for data in sprite.images {
                if let texture = try? draw2D.textureLoader.newTexture(data: data, options: options) {
                    group.images.append(texture)
                }
            }
            imageGroups.append(group)
        }
        
        // Create the 256 hardware sprites
        sprites = []
        for index in 0..<256 {
            let sprite = Sprite(index: index)
            sprites.append(sprite)
        }
    }
    
    func draw() {        
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
                case .rect(let x, let y, let width, let height, let color, _) :
                    draw2D.currentSampler = draw2D.nearestSampler
                    draw2D.startShape(type: .triangle)
                    draw2D.drawRect(x, y, width, height, color.simd, -rota)
                    draw2D.endShape()
                    //draw2D.drawText(position: float2(100, 80), text: "test", size: 30)
                case .sprset(let spriteIndex, let imageGroupName) :
                    if let imageGroup = getImageGroup(name: imageGroupName) {
                        sprites[spriteIndex].imageGroup = imageGroup
                        sprites[spriteIndex].currentImageIndex = 0
                        sprites[spriteIndex].size.width = CGFloat(imageGroup.images[0].width)
                        sprites[spriteIndex].size.height = CGFloat(imageGroup.images[0].height)
                    }
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
        
        for sprite in sprites {
            if let imageGroup = sprite.imageGroup {
                let index = sprite.currentImageIndex
                draw2D.startShape(type: .triangle)
                draw2D.drawRect(0, 0, Float(imageGroup.images[index].width), Float(imageGroup.images[index].height), float4(0, 0, 0, 1), 0.0)
                draw2D.endShape(externalTexture: imageGroup.images[index])
            }
        }
        
        draw2D.encodeEnd()
        cmds.removeAll()
    }
        
    func getImageGroup(name: String) -> ImageGroup? {
        return imageGroups.first { $0.name == name }
    }
}

