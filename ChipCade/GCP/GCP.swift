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
    case spract(spriteIndex: Int, value: Int)
    case sprx(spriteIndex: Int, value: Int)
    case spry(spriteIndex: Int, value: Int)
    case sprroo(spriteIndex: Int, value: Float)
    case sprrot(spriteIndex: Int, value: Float)
    case sprspd(spriteIndex: Int, value: Float)
    case spracc(spriteIndex: Int, value: Float)
    case sprwrp(spriteIndex: Int, value: Int)
    case lyrres(layerIndex: Int, width: Int, height: Int)
    case lyrvis(layerIndex: Int, value: Int)
    case sprimg(spriteIndex: Int, value: Int)
    case sprmxs(spriteIndex: Int, value: Float)
    case sprfri(spriteIndex: Int, value: Float)
    case sprpri(spriteIndex: Int, value: Int)
    case sprgrp(spriteIndex: Int, value: Int)
    case spranm(spriteIndex: Int, from: Int, to: Int)
    case sprfps(spriteIndex: Int, value: Int)
    case sprstp(spriteIndex: Int)
    case spralp(spriteIndex: Int, value: Float)
    case sprhlt(spriteIndex: Int)
    case sprscl(spriteIndex: Int, value: Float)
    case fntset(fontName: String, fontSize: Float)
    case text(text: String, x: Float, y: Float, colorIndex: Int)
}

public class GCP {
    
    var cmds: [GCPCmd] = []
    var draw2D = MetalDraw2D()
    
    var imageGroups: [ImageGroup] = []
    var layers: [Layer] = []
    var sprites: [Sprite] = []
    
    var elapsedTime : Float = 0
    let deltaTime: Float = 1.0 / 60.0
    
    var fontSize: Float = 20.0

    var currLayer: Int = 0
    
    init() {
    }
    
    public func setupView(_ metalView: ChipCadeView)
    {
        draw2D.setupView(metalView)
        
        if layers.isEmpty {
            for _ in 0..<8 {
                if let index = draw2D.createTexture(width: 100, height: 100) {
                    let layer = Layer(index: index)
                    layers.append(layer)
                }
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
        
        elapsedTime = 0.0
    }
    
    func draw() {
        
        var layerCmds : [[GCPCmd]] = [[], [], [], [], [], [], [], []]

        let width = Int(draw2D.metalView.frame.width)
        let height = Int(draw2D.metalView.frame.height)
        
        let screenSize = CGSize(width: CGFloat(width), height: CGFloat(height))

        // Update the sprite positions
        for sprite in sprites {
            if sprite.isActive {
                sprite.updatePosition()
                
                
                if sprite.isWrapped {
                    // Default to screen size
                    var layerSize = screenSize

                    // If sprite is associated with a layer, use the layer size
                    if let layerIndex = sprite.layer, let size = layers[layerIndex].size {
                        layerSize = size
                    }

                    // Buffer zone for wrapping
                    let bufferX = sprite.size.width
                    let bufferY = sprite.size.height

                    // Wrap horizontally only if completely off-screen
                    if sprite.position.x < -bufferX {
                        // sprite.position.x += layerSize.width + bufferX
                        sprite.position.x = layerSize.width - bufferX
                    } else if sprite.position.x > layerSize.width {
                        // sprite.position.x -= layerSize.width + bufferX
                        sprite.position.x = 0
                    }

                    // Wrap vertically only if completely off-screen
                    if sprite.position.y < -bufferY {
                        //sprite.position.y += layerSize.height + bufferY
                        sprite.position.y = layerSize.height - bufferY
                    } else if sprite.position.y > layerSize.height {
                        //sprite.position.y -= layerSize.height + bufferY
                        sprite.position.y = 0
                    }
                }
            }
        }

        // Make sure the layers are in the correct size (either screen or custom layer size)
        for layer in layers {
            if layer.size == nil {
                draw2D.syncTextureToView(index: layer.index)
            } else {
                draw2D.ensureTextureSize(index: layer.index, width: Int(layer.size!.width), height: Int(layer.size!.height))
            }
        }
        
        // Process all graphic commands
        let targetLayer = 0
        
        draw2D.setTarget(id: targetLayer)
        draw2D.setTexture(id: 0)

        draw2D.encodeStart(.clear)
        //draw2D.clear(color: float4(0.0, 0.0, 0.0, 0.0))

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
                
            case .spract(let spriteIndex, let value) :
                sprites[spriteIndex].isActive = Bool(value != 0)
             
            case .sprroo(let spriteIndex, let value) :
                sprites[spriteIndex].rotationOffset = CGFloat(value)
                
            case .sprrot(let spriteIndex, let value) :
                sprites[spriteIndex].setRotation(value)
                
            case .sprx(let spriteIndex, let value) :
                sprites[spriteIndex].position.x = CGFloat(value)
                
            case .spry(let spriteIndex, let value) :
                sprites[spriteIndex].position.y = CGFloat(value)
                
            case .sprspd(let spriteIndex, let value) :
                sprites[spriteIndex].speed = CGFloat(value)
                sprites[spriteIndex].updateVelocity()
                
            case .spracc(let spriteIndex, let value) :
                sprites[spriteIndex].acceleration = CGFloat(value)
                sprites[spriteIndex].applyAccelerationImpulse()
                
            case .sprwrp(let spriteIndex, let value) :
                sprites[spriteIndex].isWrapped = value == 1
                
            case .sprimg(let spriteIndex, let value) :
                sprites[spriteIndex].currentImageIndex = value
                sprites[spriteIndex].isAnimating = false
                
            case .sprpri(let spriteIndex, let value) :
                sprites[spriteIndex].priority = value
                
            case .sprmxs(let spriteIndex, let value) :
                sprites[spriteIndex].maxSpeed = CGFloat(value)
                
            case .sprfri(let spriteIndex, let value) :
                sprites[spriteIndex].friction = CGFloat(value)
                
            case .sprgrp(let spriteIndex, let value) :
                sprites[spriteIndex].collisionGroupIndex = value
                
            case .spranm(let spriteIndex, let from, let to) :
                let sprite = sprites[spriteIndex]
                sprite.animationRange = from...to
                sprite.isAnimating = true
                if !sprite.animationRange.contains(sprite.currentImageIndex) {
                    sprite.currentImageIndex = from
                    sprite.timeSinceLastFrame = 0.0
                }
                
            case .sprfps(let spriteIndex, let value) :
                sprites[spriteIndex].animationSpeed = Float(value)
                
            case .sprstp(let spriteIndex) :
                sprites[spriteIndex].animationStop = true
                sprites[spriteIndex].currentImageIndex = 0
                
            case .sprhlt(let spriteIndex) :
                sprites[spriteIndex].velocity = .zero
                
            case .spralp(let spriteIndex, let value) :
                sprites[spriteIndex].alpha = CGFloat(value)
                
            case .sprscl(let spriteIndex, let value) :
                sprites[spriteIndex].scale = CGFloat(value)
                
            case .fntset(let fontName, let size) :
                draw2D.font = draw2D.fonts[fontName]!
                fontSize = size
                
            case .text(_, _, _, _):
                layerCmds[currLayer].append(cmd)
            }
        }
        
        draw2D.encodeEnd()

        // Draw all sprites bound to a layer and all draw cmds
        
        for layerIndex in 0..<8 {
            let layer = layers[layerIndex]
            if layer.isVisible {
                draw2D.setTarget(id: 1)
                draw2D.setTexture(id: 0)
                draw2D.encodeStart(.clear, float4(0.0, 0.0, 0.0, 1.0))
                //draw2D.clear(color: float4(0.0, 0.0, 0.0, 1.0))

                // Draw sprites
                
                var scaleX : Float = 1.0
                var scaleY : Float = 1.0
                
                if let layerSize = layer.size {
                    scaleX = Float(layerSize.width) / Float(width)
                    scaleY = Float(layerSize.height) / Float(height)
                }
                
                let sortedSprites = sortedSprites(in: layerIndex, from: sprites)
                for sprite in sortedSprites {
                    if let imageGroup = sprite.imageGroup, sprite.isActive, sprite.layer == layerIndex{
                        let index = sprite.currentImageIndex
                        
                        // Sanity check for image index
                        if index >= imageGroup.images.count {
                            continue
                        }
                        
                        // Calculate the sprite's scaled position
                        let spriteX = Float(sprite.position.x) / scaleX
                        let spriteY = Float(sprite.position.y) / scaleY
                        
                        let spriteWidth = Float(imageGroup.images[index].width) / scaleX * Float(sprite.scale)
                        let spriteHeight = Float(imageGroup.images[index].height) / scaleY * Float(sprite.scale)
                        
                        // Calculate aspect ratio correction factors
                        let aspectX = scaleX
                        let aspectY = scaleY
                        
                        if sprite.isAnimating {
                            sprite.timeSinceLastFrame += deltaTime
                            let frameDuration = 1.0 / sprite.animationSpeed
                            if sprite.timeSinceLastFrame >= frameDuration {
                                sprite.timeSinceLastFrame = 0.0
                                sprite.currentImageIndex += 1
                                if sprite.currentImageIndex > sprite.animationRange.last! {
                                    sprite.currentImageIndex = sprite.animationRange.first!
                                    if sprite.animationStop {
                                        sprite.isActive = false
                                        sprite.animationStop = false
                                    }
                                }
                            }
                        }
                        
                        draw2D.startShape(type: .triangle)
                        draw2D.drawRect(spriteX, spriteY, spriteWidth, spriteHeight, float4(0, 0, 0, Float(sprite.alpha)), Float(sprite.rotation + sprite.rotationOffset), aspectX, aspectY)
                        draw2D.endShape(externalTexture: imageGroup.images[index])
                        
                        if sprite.isWrapped {
                            // The sprite gets wrapped around the layer dimensions
                            // We need to blit off screen sprite areas on the mirror side
                            let bufferX = sprite.size.width
                            let bufferY = sprite.size.height
                            
                            var layerSize = screenSize
                            if let layerIndex = sprite.layer, let size = layers[layerIndex].size {
                                layerSize = size
                            }
                            
                            // Horizontal blitting for wraps
                            if sprite.position.x < 0 {
                                let x = sprite.position.x
                                if x > -bufferX {
                                    draw2D.startShape(type: .triangle)
                                    draw2D.drawRect(Float(layerSize.width + x) / scaleX, spriteY, spriteWidth, spriteHeight, float4(0, 0, 0, 1), Float(sprite.rotation + sprite.rotationOffset), aspectX, aspectY)
                                    draw2D.endShape(externalTexture: imageGroup.images[index])
                                }
                            } else if sprite.position.x > layerSize.width - bufferX {
                                let x = sprite.position.x - (layerSize.width - bufferX)
                                if x < bufferX {
                                    draw2D.startShape(type: .triangle)
                                    draw2D.drawRect(Float(x - bufferX) / scaleX, spriteY, spriteWidth, spriteHeight, float4(0, 0, 0, 1), Float(sprite.rotation + sprite.rotationOffset), aspectX, aspectY)
                                    draw2D.endShape(externalTexture: imageGroup.images[index])
                                }
                            }
                            
                            // Vertical blitting for wraps
                            if sprite.position.y < 0 {
                                let y = sprite.position.y
                                if y >= -bufferY {
                                    draw2D.startShape(type: .triangle)
                                    draw2D.drawRect(spriteX, Float(layerSize.height + y + 1) / scaleY, spriteWidth, spriteHeight, float4(0, 0, 0, 1), Float(sprite.rotation + sprite.rotationOffset), aspectX, aspectY)
                                    draw2D.endShape(externalTexture: imageGroup.images[index])
                                }
                            } else if sprite.position.y > layerSize.height - bufferY {
                                let y = sprite.position.y - (layerSize.height - bufferY)
                                if y < bufferY {
                                    draw2D.startShape(type: .triangle)
                                    draw2D.drawRect(spriteX, Float(y - bufferY) / scaleY, spriteWidth, spriteHeight, float4(0, 0, 0, 1), Float(sprite.rotation + sprite.rotationOffset), aspectX, aspectY)
                                    draw2D.endShape(externalTexture: imageGroup.images[index])
                                }
                            }
                        }
                    }
                }
                
                // Draw cmds
                for cmd in layerCmds[layerIndex] {
                    switch cmd {
                    case .text(let text, let x, let y, let colorIndex):
                        draw2D.drawText(position: float2(x, y), text: text, size: fontSize, color: Game.shared.data.palette[colorIndex])
                    default:
                        break;
                    }
                }
                
                draw2D.encodeEnd()
            }
        }
        
        
        // Copy the active layers onto the screen
        
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
        
        // Draw all sprites which are not in a layer

        draw2D.setTarget(id: 0)
        draw2D.setTexture(id: 0)
        draw2D.encodeStart()

        for sprite in sprites {
            if let imageGroup = sprite.imageGroup, sprite.isActive, sprite.layer == nil {
                let index = sprite.currentImageIndex
                
                if sprite.isAnimating {
                    sprite.timeSinceLastFrame += deltaTime
                    let frameDuration = 1.0 / sprite.animationSpeed
                    if sprite.timeSinceLastFrame >= frameDuration {
                        sprite.timeSinceLastFrame = 0.0
                        sprite.currentImageIndex += 1
                        if sprite.currentImageIndex > sprite.animationRange.last! {
                            sprite.currentImageIndex = sprite.animationRange.first!
                        }
                    }
                }
                draw2D.startShape(type: .triangle)
                draw2D.drawRect(Float(sprite.position.x), Float(sprite.position.y), Float(imageGroup.images[index].width) * Float(sprite.scale), Float(imageGroup.images[index].height) * Float(sprite.scale), float4(0, 0, 0, Float(sprite.alpha)), Float(-sprite.rotation))
                draw2D.endShape(externalTexture: imageGroup.images[index])
            }
        }
        draw2D.encodeEnd()

        // Clear all commands as processed
        cmds.removeAll()
        
        elapsedTime += deltaTime
    }
     
    // Get the image group of the given name
    func getImageGroup(name: String) -> ImageGroup? {
        return imageGroups.first { $0.name == name }
    }
    
    // Sort the sprites based on their layer and priority
    func sortedSprites(in layerIndex: Int?, from sprites: [Sprite]) -> [Sprite] {
        // Filter sprites that belong to the given layer
        let layerSprites = sprites.filter { $0.layer == layerIndex }
        
        // Sort the filtered sprites by priority (ascending)
        let sortedSprites = layerSprites.sorted { $0.priority < $1.priority }
        
        return sortedSprites
    }
}

