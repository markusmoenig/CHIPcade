//
//  MetalDraw2D.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import MetalKit

extension MTLVertexDescriptor {
    static var defaultLayout: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.stride * 4
        vertexDescriptor.attributes[2].bufferIndex = 0

        let stride = MemoryLayout<Float>.stride * 8
        vertexDescriptor.layouts[0].stride = stride
        return vertexDescriptor
    }
}

class MetalDraw2D
{
    var metalView       : ChipCadeView!
    
    var device          : MTLDevice!
    var commandQueue    : MTLCommandQueue!
    
    var pipelineState   : MTLRenderPipelineState! = nil
    var pipelineStateDesc : MTLRenderPipelineDescriptor! = nil

    var renderEncoder   : MTLRenderCommandEncoder! = nil

    var vertexBuffer    : MTLBuffer? = nil
    var viewportSize    : vector_uint2
    
    var commandBuffer   : MTLCommandBuffer! = nil
    
    var polyState       : MTLRenderPipelineState? = nil
    var textState       : MTLRenderPipelineState? = nil
    var copyState       : MTLRenderPipelineState? = nil
    var boxState        : MTLRenderPipelineState? = nil
    var gridState       : MTLRenderPipelineState? = nil
    var lineState       : MTLRenderPipelineState? = nil

    var scaleFactor     : Float
    var viewSize        = float2(0,0)
    
    var vertexData      : [Float] = []
    var vertexCount     : Int = 0
    
    var primitiveType   : MTLPrimitiveType = .triangle
    
    var frameworkId     : String? = nil

    var textures        : [Int:MTLTexture] = [:]
    var textureIdCount  : Int = 1
    
    var target          : Int? = nil
    var texture         : Int? = nil

    var textureLoader   : MTKTextureLoader!

    var fonts           : [String:Font] = [:]
    var font            : Font! = nil

    var nearestSampler  : MTLSamplerState!
    var linearSampler   : MTLSamplerState!
    var currentSampler  : MTLSamplerState!

    var cpuView         : ChipCadeView!
    var cpuWidget       : CPUWidget!
    
    var id              = UUID()

    public init(_ frameworkId: String? = nil)
    {
        self.frameworkId = frameworkId
        
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif
    }
    
    public func setupView(_ metalView: ChipCadeView)
    {
        self.metalView = metalView
        #if os(iOS)
        metalView.layer.isOpaque = false
        #elseif os(macOS)
        metalView.layer?.isOpaque = false
        #endif

        device = metalView.device!
        viewportSize = vector_uint2( UInt32(metalView.bounds.width), UInt32(metalView.bounds.height) )
        commandQueue = device.makeCommandQueue()
        
        textureLoader = MTKTextureLoader(device: device!)
                    
        if let defaultLibrary = device.makeDefaultLibrary() {

            pipelineStateDesc = MTLRenderPipelineDescriptor()
            let vertexFunction = defaultLibrary.makeFunction( name: "poly2DVertex" )
            pipelineStateDesc.vertexFunction = vertexFunction
            pipelineStateDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
            
            pipelineStateDesc.vertexDescriptor = MTLVertexDescriptor.defaultLayout
            
            pipelineStateDesc.colorAttachments[0].isBlendingEnabled = true
            pipelineStateDesc.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDesc.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineStateDesc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineStateDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                        
            func createNewPipelineState(_ fragmentFunction: MTLFunction?) -> MTLRenderPipelineState?
            {
                if let function = fragmentFunction {
                    pipelineStateDesc.fragmentFunction = function
                    do {
                        let renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDesc)
                        return renderPipelineState
                    } catch {
                        print( "createNewPipelineState failed" )
                        return nil
                    }
                }
                return nil
            }
            
            var function = defaultLibrary.makeFunction( name: "poly2DFragment" )
            polyState = createNewPipelineState(function)
            
            function = defaultLibrary.makeFunction( name: "m4mTextDrawable" )
            textState = createNewPipelineState(function)
            
            function = defaultLibrary.makeFunction( name: "m4mCopyTextureDrawable" )
            copyState = createNewPipelineState(function)
            
            function = defaultLibrary.makeFunction( name: "m4mBoxDrawable" )
            boxState = createNewPipelineState(function)
            
            function = defaultLibrary.makeFunction( name: "m4mGridDrawable" )
            gridState = createNewPipelineState(function)
            
            function = defaultLibrary.makeFunction( name: "m4mLineDrawable" )
            lineState = createNewPipelineState(function)
        }
        
        // Create linear and nearest samplers
        let linearSamplerDescriptor = MTLSamplerDescriptor()
        linearSamplerDescriptor.minFilter = .linear
        linearSamplerDescriptor.magFilter = .linear
        linearSamplerDescriptor.sAddressMode = .repeat
        linearSamplerDescriptor.tAddressMode = .repeat

        linearSampler = device.makeSamplerState(descriptor: linearSamplerDescriptor)

        let nearestSamplerDescriptor = MTLSamplerDescriptor()
        nearestSamplerDescriptor.minFilter = .nearest
        nearestSamplerDescriptor.magFilter = .nearest

        currentSampler = linearSampler
        
        nearestSampler = device.makeSamplerState(descriptor: nearestSamplerDescriptor)
        
        // Init the SDF fonts
        
        var font = Font(name: "OpenSans", draw: self)
        fonts["opensans"] = font
        
        font = Font(name: "Square", draw: self)
        fonts["square"] = font
        
        font = Font(name: "SquadaOne", draw: self)
        fonts["squadaone"] = font
        
        self.font = font
    }
    
//    public func draw()
//    {
//        encodeStart()
//        clear(color: float4(0.125, 0.129, 0.137, 1))
//        startShape(type: .triangle)
//        drawRect(10, 40, 200, 200, float4(1, 0, 1, 1), 0.0)
//        endShape()
//        drawText(position: float2(100, 100), text: "CHIPCADE", size: 30)
//        encodeEnd()
//    }
    
    @discardableResult func encodeStart(_ loadAction: MTLLoadAction = .load,_ clearColor: float4 = float4(0.0, 0.0, 0.0, 0.0)) -> MTLRenderCommandEncoder?
    {
        viewportSize = vector_uint2( UInt32(metalView.bounds.width), UInt32(metalView.bounds.height) )
        viewSize = float2(Float(metalView.bounds.width), Float(metalView.bounds.height))

        commandBuffer = commandQueue.makeCommandBuffer()!
        var renderPassDescriptor : MTLRenderPassDescriptor?
        
        if target == nil {
            renderPassDescriptor = metalView.currentRenderPassDescriptor
        } else {
            renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor?.colorAttachments[0].texture = textures[target!]
        }
        
//        renderPassDescriptor!.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor( red: Double(clearColor.x), green: Double(clearColor.y), blue: Double(clearColor.z), alpha: Double(clearColor.w))
////
        renderPassDescriptor!.colorAttachments[0].loadAction = loadAction
        
        if loadAction == .clear {
            renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor( red: Double(clearColor.x), green: Double(clearColor.y), blue: Double(clearColor.z), alpha: Double(clearColor.w))
        }
        
        renderPassDescriptor!.colorAttachments[0].storeAction = .store
        
        //renderPassDescriptor!.colorAttachments[0].loadAction = .dontCare

        if renderPassDescriptor != nil {
            renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor! )
            return renderEncoder
        }
        
        return nil
    }
    
    func encodeRun( _ renderEncoder: MTLRenderCommandEncoder, pipelineState: MTLRenderPipelineState? )
    {
        renderEncoder.setRenderPipelineState( pipelineState! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func encodeEnd()
    {
        renderEncoder?.endEncoding()
        
        if target == nil {
            guard let drawable = metalView.currentDrawable else {
                return
            }
            
            if let commandBuffer = commandBuffer {
                //commandBuffer.addCompletedHandler { cb in
                //    print("Rendering Time:", (cb.gpuEndTime - cb.gpuStartTime) * 1000)
                //}
                commandBuffer.present(drawable)
                commandBuffer.commit()
//                commandBuffer.waitUntilCompleted()
            }
        } else {
            commandBuffer.commit()
        }
    }
    
    func startShape(type: MTLPrimitiveType = .triangle) {
        primitiveType = type
        vertexData = []
        vertexCount = 0
    }
    
    func addVertex(_ vertex: float2,_ textureCoordinate: float2,_ color: float4) {
        vertexData.append(-viewSize.x / 2.0 + vertex.x * 1)
        vertexData.append(viewSize.y / 2.0 - vertex.y * 1)
        vertexData.append(textureCoordinate.x)
        vertexData.append(textureCoordinate.y)
        vertexData.append(color.x)
        vertexData.append(color.y)
        vertexData.append(color.z)
        vertexData.append(color.w)
        vertexCount += 1
    }
    
    // Drawing with uniform scaling
    func drawRect(_ x: Float, _ y: Float, _ width: Float, _ height: Float,_ c: float4 = float4(0, 0, 0, 1), _ rot: Float = 0.0) {
        
        //        right, bottom, 1.0, 0.0,
        //        left, bottom, 0.0, 0.0,
        //        left, top, 0.0, 1.0,
        //
        //        right, bottom, 1.0, 0.0,
        //        left, top, 0.0, 1.0,
        //        right, top, 1.0, 1.0,
        
        if rot == 0.0 {
            let arr : [Float ] = [
                xToMetal(x + width), yToMetal(y + height), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(x), yToMetal(y + height), 0.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(x), yToMetal(y), 0.0, 1.0, c.x, c.y, c.z, c.w,
                 
                xToMetal(x + width), yToMetal(y + height), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(x), yToMetal(y), 0.0, 1.0, c.x, c.y, c.z, c.w,
                xToMetal(x + width), yToMetal(y), 1.0, 1.0, c.x, c.y, c.z, c.w,
            ]
            
            vertexData.append(contentsOf: arr)
            vertexCount += 6
        } else {
                        
            let radians = rot.degreesToRadians
            let cos = cos(radians)
            let sin = sin(radians)
            let cx = x + width / 2.0
            let cy = y + height / 2.0

            func rotate(x : Float, y : Float) -> (Float, Float) {
                let nx = (cos * (x - cx)) + (sin * (y - cy)) + cx
                let ny = (cos * (y - cy)) - (sin * (x - cx)) + cy
                return (nx, ny)
            }

            let topLeft = rotate(x: x, y: y)
            let topRight = rotate(x: x + width, y: y)
            let bottomLeft = rotate(x: x, y: y + height)
            let bottomRight = rotate(x: x + width, y: y + height)
            
            let arr : [Float ] = [
                xToMetal(bottomRight.0), yToMetal(bottomRight.1), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(bottomLeft.0), yToMetal(bottomLeft.1), 0.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(topLeft.0), yToMetal(topLeft.1), 0.0, 1.0, c.x, c.y, c.z, c.w,
                 
                xToMetal(bottomRight.0), yToMetal(bottomRight.1), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(topLeft.0), yToMetal(topLeft.1), 0.0, 1.0, c.x, c.y, c.z, c.w,
                xToMetal(topRight.0), yToMetal(topRight.1), 1.0, 1.0, c.x, c.y, c.z, c.w,
            ]
            
            vertexData.append(contentsOf: arr)
            vertexCount += 6
        }
    }
    
    // Drawing with non uniform scaling
    func drawRect(_ x: Float, _ y: Float, _ width: Float, _ height: Float, _ c: float4 = float4(0, 0, 0, 1), _ rot: Float = 0.0, _ scaleX: Float = 1.0, _ scaleY: Float = 1.0) {

        if rot == 0.0 {
            // No rotation case
            let arr: [Float] = [
                xToMetal(x + width), yToMetal(y + height), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(x), yToMetal(y + height), 0.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(x), yToMetal(y), 0.0, 1.0, c.x, c.y, c.z, c.w,
                 
                xToMetal(x + width), yToMetal(y + height), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(x), yToMetal(y), 0.0, 1.0, c.x, c.y, c.z, c.w,
                xToMetal(x + width), yToMetal(y), 1.0, 1.0, c.x, c.y, c.z, c.w,
            ]
            
            vertexData.append(contentsOf: arr)
            vertexCount += 6
        } else {
            // Rotation case with aspect correction
            let radians = rot.degreesToRadians
            let cosAngle = cos(radians)
            let sinAngle = sin(radians)

            // Center of the rectangle
            let cx = x + width / 2.0
            let cy = y + height / 2.0

            // Helper function to rotate with aspect correction
            func rotate(x: Float, y: Float) -> (Float, Float) {
                let scaledX = (x - cx) * scaleX
                let scaledY = (y - cy) * scaleY

                let nx = cosAngle * scaledX - sinAngle * scaledY
                let ny = sinAngle * scaledX + cosAngle * scaledY

                return (nx / scaleX + cx, ny / scaleY + cy)
            }

            // Calculate the rotated vertices with aspect correction
            let topLeft = rotate(x: x, y: y)
            let topRight = rotate(x: x + width, y: y)
            let bottomLeft = rotate(x: x, y: y + height)
            let bottomRight = rotate(x: x + width, y: y + height)

            let arr: [Float] = [
                xToMetal(bottomRight.0), yToMetal(bottomRight.1), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(bottomLeft.0), yToMetal(bottomLeft.1), 0.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(topLeft.0), yToMetal(topLeft.1), 0.0, 1.0, c.x, c.y, c.z, c.w,
                 
                xToMetal(bottomRight.0), yToMetal(bottomRight.1), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(topLeft.0), yToMetal(topLeft.1), 0.0, 1.0, c.x, c.y, c.z, c.w,
                xToMetal(topRight.0), yToMetal(topRight.1), 1.0, 1.0, c.x, c.y, c.z, c.w,
            ]
            
            vertexData.append(contentsOf: arr)
            vertexCount += 6
        }
    }
    
    func endShape(externalTexture: MTLTexture? = nil) {
        if !vertexData.isEmpty {
            var data = RectUniform()
            data.hasTexture = 0;
            
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            
            if let externalTexture = externalTexture {
                data.hasTexture = 1
                renderEncoder.setFragmentTexture(externalTexture, index: 1)
            } else
            if texture != nil {
                if let tex = textures[texture!] {
                    data.hasTexture = 1
                    renderEncoder.setFragmentTexture(tex, index: 1)
                }
            }
            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<RectUniform>.stride, index: 0)
            renderEncoder.setFragmentSamplerState(linearSampler, index: 0)

            renderEncoder.setRenderPipelineState(polyState!)
            renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: vertexCount)
        }
        
        vertexData = []
        vertexCount = 0
    }
    
    func clear(color: float4) {
        let size = viewSize
                
        startShape(type: .triangle)
        addVertex(float2(size.x, size.y), float2(1.0, 0.0), color)
        addVertex(float2(0, size.y), float2(0.0, 0.0), color)
        addVertex(float2(0, 0), float2(0.0, 1.0), color)
        
        addVertex(float2(size.x, size.y), float2(1.0, 0.0), color)
        addVertex(float2(0, 0), float2(0.0, 1.0), color)
        addVertex(float2(size.x, 0), float2(1.0, 1.0), color)
        endShape()
    }
    
    func copyTexture()
    {
        if texture != nil {
            if let texture = textures[texture!] {
                
                let width : Float = Float(texture.width)
                let height: Float = Float(texture.height)

                var data = TextureUniform()
                data.screenSize.x = Float(texture.width)
                data.screenSize.y = Float(texture.height)
                data.pos.x = 0
                data.pos.y = 0
                data.size.x = width * scaleFactor
                data.size.y = height * scaleFactor
                data.globalAlpha = 1
                
                //let rect = MRRect(0, 0, width, height, scale: 1)
                let color = float4(0,0,0,1)
                
//                vertexData = [
//                    xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
//                    xToMetal(rect.x), yToMetal(rect.y + rect.height), 0.0, 0.0, c.x, c.y, c.z, c.w,
//                    xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
//                     
//                    xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
//                    xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
//                    xToMetal(rect.x + rect.width), yToMetal(rect.y), 1.0, 1.0, c.x, c.y, c.z, c.w,
//                ]
//                vertexCount = 6
                
                let size = viewSize
                startShape(type: .triangle)
                addVertex(float2(size.x, size.y), float2(1.0, 0.0), color)
                addVertex(float2(0, size.y), float2(0.0, 0.0), color)
                addVertex(float2(0, 0), float2(0.0, 1.0), color)
                
                addVertex(float2(size.x, size.y), float2(1.0, 0.0), color)
                addVertex(float2(0, 0), float2(0.0, 1.0), color)
                addVertex(float2(size.x, 0), float2(1.0, 1.0), color)
                
                renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
                renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

                renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextureUniform>.stride, index: 0)
                renderEncoder.setFragmentTexture(texture, index: 1)

                renderEncoder.setRenderPipelineState(copyState!)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                
                vertexData = []
                vertexCount = 0
                /*
                
                let width : Float = Float(texture!.width)
                let height: Float = Float(texture.height)
                
                var settings = TextureUniform()
                settings.screenSize.x = Float(texture.width)//screenWidth
                settings.screenSize.y = Float(texture.height)//screenHeight
                settings.pos.x = 0
                settings.pos.y = 0
                settings.size.x = width * scaleFactor
                settings.size.y = height * scaleFactor
                settings.globalAlpha = 1
                
                let rect = MMRect( 0, 0, width, height, scale: scaleFactor )
                let vertexData = createVertexData(texture: texture, rect: rect)
                
                var viewportSize = vector_uint2( UInt32(texture.width), UInt32(texture.height))
                
                renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
                renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
                
                renderEncoder.setFragmentBytes(&settings, length: MemoryLayout<TextureUniform>.stride, index: 0)
                renderEncoder.setFragmentTexture(texture, index: 1)
                
                renderEncoder.setRenderPipelineState(metalStates.getState(state: .CopyTexture))
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                */
            }
        }
    }
    
    /// Draws a box
    func drawLine(startPos: float2, endPos: float2, radius: Float, borderSize: Float = 0, fillColor: float4 = float4(1,1,1,1), borderColor: float4 = float4(0,0,0,0))
    {
        let sx = startPos.x
        let sy = startPos.y
        let ex = endPos.x
        let ey = endPos.y
        
        let minX = min(sx, ex)
        let maxX = max(sx, ex)
        let minY = min(sy, ey)
        let maxY = max(sy, ey)
        
        let areaWidth : Float = maxX - minX + borderSize + radius * 2
        let areaHeight : Float = maxY - minY + borderSize + radius * 2
                
        let middleX : Float = (sx + ex) / 2
        let middleY : Float = (sy + ey) / 2
        
        var data = LineUniform()
        data.size = float2(areaWidth, areaHeight)
        data.width = radius
        data.borderSize = borderSize
        data.fillColor = fillColor
        data.borderColor = borderColor
        data.sp = float2(sx - middleX, middleY - sy)
        data.ep = float2(ex - middleX, middleY - ey)

        let rect = MMRect( minX - borderSize / 2, minY - borderSize / 2, areaWidth, areaHeight, scale: 1)
        let c = fillColor
        
        vertexData = [
            xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y + rect.height), 0.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
             
            xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x + rect.width), yToMetal(rect.y), 1.0, 1.0, c.x, c.y, c.z, c.w,
        ]
        vertexCount = 6
        
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<LineUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(lineState!)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }

    
    /// Draws a box
    func drawBox(position: float2, size: float2, rounding: Float = 0, borderSize: Float = 0, onion: Float = 0, rotation: Float = 0, fillColor: float4 = float4(1,1,1,1), borderColor: float4 = float4(0,0,0,0), texture: MTLTexture? = nil)
    {
        var data = BoxUniform()
        data.borderSize = borderSize
        data.size = size
        data.fillColor = fillColor
        data.borderColor = borderColor
        data.onion = onion
        data.rotation = rotation.degreesToRadians
        data.hasTexture = texture != nil ? 1 : 0
        data.round = rounding

        let rect = MMRect(position.x - data.borderSize / 2, position.y - data.borderSize / 2, size.x + data.borderSize * 2, size.y + data.borderSize * 2, scale: 1)

        let c = fillColor
        
        vertexData = [
            xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y + rect.height), 0.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
             
            xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x + rect.width), yToMetal(rect.y), 1.0, 1.0, c.x, c.y, c.z, c.w,
        ]
        vertexCount = 6
        
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
        if let texture = texture {
            renderEncoder.setFragmentTexture(texture, index: 1)
        }
        renderEncoder.setRenderPipelineState(boxState!)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /// Draws grid
    func drawGrid(offset: float2, gridSize: Float, backgroundColor: float4)
    {
        var data = GridUniform()
        data.size = viewSize
        data.offset = offset
        data.gridSize = gridSize

        let rect = MMRect(0, 0, viewSize.x, viewSize.y, scale: 1)

        let c = backgroundColor
        
        vertexData = [
            xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y + rect.height), 0.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
             
            xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
            xToMetal(rect.x + rect.width), yToMetal(rect.y), 1.0, 1.0, c.x, c.y, c.z, c.w,
        ]
        vertexCount = 6
        
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<GridUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(gridState!)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /// Draws the given text
    func drawText(position: float2, text: String, size: Float, color: float4 = float4(1,1,1,1), rotated: Int = 0)
    {
        func drawChar(char: BMChar, x: Float, y: Float, adjScale: Float)
        {
            var data = TextUniform()
            
            data.atlasSize.x = Float(font!.atlas!.width)
            data.atlasSize.y = Float(font!.atlas!.height)
            data.fontPos.x = char.x
            data.fontPos.y = char.y
            data.fontSize.x = char.width
            data.fontSize.y = char.height
            data.rotated = Int32(rotated)

            let rect = MRRect(x, y, char.width * adjScale * (rotated == 0 ? 1 : 2), char.height * adjScale, scale: 1)
            
            let c = color
            
            vertexData = [
                xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(rect.x), yToMetal(rect.y + rect.height), 0.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
                 
                xToMetal(rect.x + rect.width), yToMetal(rect.y + rect.height), 1.0, 0.0, c.x, c.y, c.z, c.w,
                xToMetal(rect.x), yToMetal(rect.y), 0.0, 1.0, c.x, c.y, c.z, c.w,
                xToMetal(rect.x + rect.width), yToMetal(rect.y), 1.0, 1.0, c.x, c.y, c.z, c.w,
            ]
            vertexCount = 6
            
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(font!.atlas, index: 1)

            renderEncoder.setRenderPipelineState(textState!)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            
            vertexData = []
            vertexCount = 0
        }
        
        if let font = font {
         
            let scale : Float = (1.0 / font.bmFont!.common.lineHeight) * size
            let adjScale : Float = scale// / 2
            
            var posX = position.x// / game.scaleFactor
            var posY = position.y// / game.scaleFactor

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    drawChar(char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: posY + bmChar!.yoffset * adjScale, adjScale: adjScale)
                    if rotated == 0 {
                        posX += bmChar!.xadvance * adjScale
                    } else {
                        posY -= bmChar!.xadvance * adjScale + size / 5
                    }
                }
            }
        }
    
        vertexData = []
        vertexCount = 0
    }
    
    /// Sets the current font
    func setFont(name: String) -> Bool
    {
        if let font = fonts[name] {
            self.font = font
            return true
        }
        return false
    }
    
    /// Gets the width of the given text
    func getTextSize(text: String, size: Float) -> float2
    {
        var rc = float2()
        
        if let font = font {
         
            let scale : Float = (1.0 / font.bmFont!.common.lineHeight) * size
            let adjScale : Float = scale// / 2
            
            var posX : Float = 0

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    posX += bmChar!.xadvance * adjScale
                }
            }
            
            rc.x = posX
            rc.y = font.bmFont!.common.lineHeight
        }
        return rc
    }
    
    /// Updates the view
    func update() {

        guard metalView != nil else {
            print("metalView \(id) is nil during update")
            return
        }
        
        metalView.enableSetNeedsDisplay = true
        #if os(OSX)
        let nsrect : NSRect = NSRect(x:0, y: 0, width: metalView.frame.width, height: metalView.frame.height)
        metalView.setNeedsDisplay(nsrect)
        #else
        metalView.setNeedsDisplay()
        #endif
    }
    
    /// Create a texture and return its id
    func createTexture(width: Int, height: Int) -> Int?
    {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = width == 0 ? 1 : width
        textureDescriptor.height = height == 0 ? 1 : height
                
        //textureDescriptor.usage = MTLTextureUsage.unknown
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        
        print("Creating Texture \(textureIdCount): \(texture.width)x\(texture.height)")
        
        let id = textureIdCount
        textures[id] = texture
        textureIdCount += 1
        return id
    }
    
    /// Resize all textures to the view size
    func syncTexturesToView() {
        let viewWidth = Int(metalView.frame.width)
        let viewHeight = Int(metalView.frame.height)
        
        textureIdCount = 1
        
        for index in 1...textures.count {
            textureIdCount = index
            if textures[index]!.width != viewWidth || textures[index]!.height != viewHeight {
                _ = createTexture(width: viewWidth, height: viewHeight)
            }
        }
    }
    
    /// Resize texture to the view size
    func syncTextureToView(index: Int) {
        let viewWidth = Int(metalView.frame.width)
        let viewHeight = Int(metalView.frame.height)
        
        textureIdCount = index
        
        if textures[index]!.width != viewWidth || textures[index]!.height != viewHeight {
            _ = createTexture(width: viewWidth, height: viewHeight)
        }
    }
    
    /// Resize texture to the view size
    func ensureTextureSize(index: Int, width: Int, height: Int) {
        textureIdCount = index
        if textures[index]!.width != width || textures[index]!.height != height {
            _ = createTexture(width: width, height: height)
        }
    }
    
    /// Sets the render target
    @discardableResult func setTarget(id: Int) -> Bool {
        if id <= 0 {
            target = nil
        } else {
            if textures.keys.contains(id) == false {
                return false
            } else {
                target = id
            }
        }
        return true
    }
    
    /// Sets the current texture
    @discardableResult func setTexture(id: Int) -> Bool {
        if id <= 0 {
            texture = nil
        } else {
            if textures.keys.contains(id) == false {
                return false
            } else {
                texture = id
            }
        }
        return true
    }
    
    /// LoadTexture
    func loadTexture(_ name: String, mipmaps: Bool = false, sRGB: Bool = false) -> Int?
    {
        let path = Bundle.main.path(forResource: name, ofType: "tiff")!
        let data = NSData(contentsOfFile: path)! as Data
        
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : mipmaps, .SRGB : sRGB]
        
        if let texture = try? self.textureLoader.newTexture(data: data, options: options) {
            let id = textureIdCount
            textures[id] = texture
            textureIdCount += 1
            return id
        }
        return nil
    }
    
    func xToMetal(_ v: Float) -> Float {
        -viewSize.x / 2.0 + v// * scaleFactor
    }
    
    func yToMetal(_ v: Float) -> Float {
        viewSize.y / 2.0 - v// * scaleFactor
    }
}
