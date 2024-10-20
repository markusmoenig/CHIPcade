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
    case sprlyr(spriteIndex: Int, value: Int)
    case sprvis(spriteIndex: Int, value: Int)
    case sprx(spriteIndex: Int, value: Int)
    case spry(spriteIndex: Int, value: Int)
    case lyrres(layerIndex: Int, width: Int, height: Int)
    case lyrvis(layerIndex: Int, value: Int)
}

public class GCP {
    
    var cmds: [GCPCmd] = []
    var draw2D = MetalDraw2D();
    
    var imageGroups: [ImageGroup] = []
    var layers: [Layer] = []
    var sprites: [Sprite] = []
    
    init() {
    }
    
    public func setupView(_ metalView: ChipCadeView)
    {
        draw2D.setupView(metalView)
        
        for _ in 0..<8 {
            if let index = draw2D.createTexture(width: 100, height: 100) {
                let layer = Layer(index: index)
                layers.append(layer)
            }
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
        for sprite in gameData.imageGroupItems {
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
        //draw2D.syncTexturesToView()
        for layer in layers {
            if layer.size == nil {
                draw2D.syncTextureToView(index: layer.index)
            } else {
                draw2D.ensureTextureSize(index: layer.index, width: Int(layer.size!.width), height: Int(layer.size!.height))
            }
        }
        
        let targetLayer = 0
//        let width = Int(draw2D.metalView.frame.width)
//        let height = Int(draw2D.metalView.frame.height)
        
        draw2D.setTarget(id: targetLayer)
        draw2D.setTexture(id: 0)

        draw2D.encodeStart()
        //draw2D.clear(color: float4(0.0, 0.0, 0.0, 1.0))

        for cmd in cmds {
            switch cmd {
                
            case .rect(let x, let y, let width, let height, let color, _) :
                draw2D.currentSampler = draw2D.nearestSampler
                draw2D.startShape(type: .triangle)
                draw2D.drawRect(x, y, width, height, color.simd, 0.0)
                draw2D.endShape()
                //draw2D.drawText(position: float2(100, 80), text: "test", size: 30)
                
                
            case .lyrres(let layerIndex, let width, let height) :
                layers[layerIndex].size = CGSize(width: CGFloat(width), height: CGFloat(height))
                
            case .lyrvis(let layerIndex, let value) :
                layers[layerIndex].isVisible = Bool(value != 0)
                
            case .sprlyr(let spriteIndex, let layerIndex) :
                sprites[spriteIndex].layer = layerIndex
                
            case .sprset(let spriteIndex, let imageGroupName) :
                if let imageGroup = getImageGroup(name: imageGroupName) {
                    sprites[spriteIndex].imageGroup = imageGroup
                    sprites[spriteIndex].currentImageIndex = 0
                    sprites[spriteIndex].size.width = CGFloat(imageGroup.images[0].width)
                    sprites[spriteIndex].size.height = CGFloat(imageGroup.images[0].height)
                }

                
            case .sprvis(let spriteIndex, let value) :
                sprites[spriteIndex].isVisible = Bool(value != 0)
                
            case .sprx(let spriteIndex, let value) :
                sprites[spriteIndex].position.x = CGFloat(value)
                
            case .spry(let spriteIndex, let value) :
                sprites[spriteIndex].position.y = CGFloat(value)
                
            }
        }
        
        draw2D.encodeEnd()

//        draw2D.setTarget(id: 0)
//        draw2D.setTexture(id: 1)
//
//        draw2D.encodeStart()
        
        //draw2D.currentSampler = draw2D.nearestSampler

//        draw2D.startShape(type: .triangle)
//        draw2D.drawRect(0, 0, Float(width), Float(height))
//        draw2D.endShape()
        
        //draw2D.copyTexture()
        
        let width = Int(draw2D.metalView.frame.width)
        let height = Int(draw2D.metalView.frame.height)
        
        // Draw all sprites bound to a texture
        for layerIndex in 0..<8 {
            let layer = layers[layerIndex]
            if layer.isVisible {
                draw2D.setTarget(id: layerIndex+1)
                draw2D.setTexture(id: 0)
                draw2D.encodeStart()
                draw2D.clear(color: float4(0.0, 0.0, 0.0, 1.0))

                var scaleX : Float = 1.0
                var scaleY : Float = 1.0
                
                if let layerSize = layer.size {
                    scaleX = Float(layerSize.width) / Float(width)
                    scaleY = Float(layerSize.height) / Float(height)
                }
                
                for sprite in sprites {
                    if let imageGroup = sprite.imageGroup, sprite.isVisible, sprite.layer == layerIndex{
                        let index = sprite.currentImageIndex
                        draw2D.startShape(type: .triangle)
                        
                        let width = Float(imageGroup.images[index].width) / scaleX
                        let height = Float(imageGroup.images[index].height) / scaleY

                        draw2D.drawRect(Float(sprite.position.x), Float(sprite.position.y), width, height, float4(0, 0, 0, 1), 0.0)
                        draw2D.endShape(externalTexture: imageGroup.images[index])
                    }
                }
                
                draw2D.encodeEnd()
            }
        }
        
        
        // Copy the active layers
        draw2D.setTarget(id: 0)
        for layerIndex in 0..<8 {
            let layer = layers[layerIndex]
            if layer.isVisible {
                draw2D.setTexture(id: layerIndex+1)
                draw2D.encodeStart()

                if let size = layer.size {
                    // Aspect ratios
                    let layerAspectRatio = size.width / size.height
                    let screenAspectRatio = CGFloat(width) / CGFloat(height)
                    
                    var scaledWidth: Float
                    var scaledHeight: Float
                    
                    // Determine scaling and maintain aspect ratio
                    if layerAspectRatio > screenAspectRatio {
                        // Fit based on width
                        scaledWidth = Float(width)
                        scaledHeight = Float(width) / Float(layerAspectRatio)
                    } else {
                        // Fit based on height
                        scaledHeight = Float(height)
                        scaledWidth = Float(height) * Float(layerAspectRatio)
                    }

                    // Calculate offsets to center the layer
                    let offsetX = (Float(width) - scaledWidth) / 2.0
                    let offsetY = (Float(height) - scaledHeight) / 2.0
                    
                    // Draw the rectangle centered and scaled
                    draw2D.startShape(type: .triangle)
                    draw2D.drawRect(offsetX, offsetY, scaledWidth, scaledHeight, float4(0, 0, 0, 1), 0.0)
                    draw2D.endShape()
                } else {
                    draw2D.copyTexture()
                }

                draw2D.encodeEnd()
            }
        }

//        draw2D.setTarget(id: 0)
//        draw2D.setTexture(id: 0)
//        draw2D.encodeStart()
//
//        // Draw all sprites which are not in a layer
//        for sprite in sprites {
//            if let imageGroup = sprite.imageGroup, sprite.isVisible, sprite.layer == nil {
//                let index = sprite.currentImageIndex
//                draw2D.startShape(type: .triangle)
//                draw2D.drawRect(Float(sprite.position.x), Float(sprite.position.y), Float(imageGroup.images[index].width), Float(imageGroup.images[index].height), float4(0, 0, 0, 1), 0.0)
//                draw2D.endShape(externalTexture: imageGroup.images[index])
//            }
//        }
//        
//        draw2D.encodeEnd()

        
        cmds.removeAll()
    }
        
    func getImageGroup(name: String) -> ImageGroup? {
        return imageGroups.first { $0.name == name }
    }
}

