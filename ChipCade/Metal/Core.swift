//
//  Core.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import MetalKit
import Combine
import AVFoundation

public class Core       : ObservableObject
{
    enum State {
        case Idle, Running, Paused
    }
    
    var state           : State = .Idle
    
    var view            : ChipCadeView!
    var device          : MTLDevice!

    var texture         : Texture2D? = nil
    var metalStates     : MetalStates!
    
    var viewportSize    : vector_uint2
    var scaleFactor     : Float
        
    var screenWidth     : Float = 0
    var screenHeight    : Float = 0

    var coreCmdQueue    : MTLCommandQueue? = nil
    var coreCmdBuffer   : MTLCommandBuffer? = nil
    var coreScissorRect : MTLScissorRect? = nil
    
    var textureLoader   : MTKTextureLoader!
        
    var resources       : [AnyObject] = []
    var availableFonts  : [String] = ["OpenSans", "Square", "SourceCodePro"]
    var fonts           : [Font] = []
    
    var _Time           = Float1(0)
    var _Aspect         = Float2(1,1)
    var _Frame          = UInt32(0)
    var targetFPS       : Float = 60
    
    // Preview Size, UI only
    var previewFactor   : CGFloat = 4
    var previewOpacity  : Double = 0.5
    
    let updateUI        = PassthroughSubject<Void, Never>()
    var didSend         = false
    
    var localAudioPlayers: [String:AVAudioPlayer] = [:]
    var globalAudioPlayers: [String:AVAudioPlayer] = [:]
    
    var showingHelp     : Bool = false
    
    var frameworkId     : String? = nil
            
    public init(_ frameworkId: String? = nil)
    {
        self.frameworkId = frameworkId
        
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
        #endif
    
    }
    
    public func setupView(_ view: ChipCadeView)
    {
        self.view = view
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            device = metalDevice
            if frameworkId != nil {
                view.device = device
            }
        } else {
            print("Cannot initialize Metal!")
        }
        view.core = self
        
        metalStates = MetalStates(self)
        textureLoader = MTKTextureLoader(device: device)
        
        /*
        for fontName in availableFonts {
            let font = Font(name: fontName, core: self)
            fonts.append(font)
        }*/
        
        view.platformInit()
        checkTexture()
    }
    
    public func start()
    {
        clearLocalAudio()
        clearGlobalAudio()
        
        view.reset()
        
        state = .Running
        
        _Aspect.x = 1
        _Aspect.y = 1

        state = .Running
        view.enableSetNeedsDisplay = false
        view.isPaused = false
            
        _Time.x = 0
        targetFPS = 60
        _Frame = 0
        
        //if let scriptEditor = scriptEditor {
        //    scriptEditor.setSilentMode(true)
        //}
    }
    
    func stop()
    {
        clearLocalAudio()
        clearGlobalAudio()
        
        //if let scriptEditor = scriptEditor {
        //    scriptEditor.setSilentMode(false)
        //}
        
        state = .Idle
        view.isPaused = true
        
        _Time.x = 0
        _Frame = 0
        //timeChanged.send(_Time.x)
    }
    
    @discardableResult func checkTexture() -> Bool
    {
        if texture == nil || texture!.texture.width != Int(view.frame.width) || texture!.texture.height != Int(view.frame.height) {
            
            if texture == nil {
                texture = Texture2D(self)
            } else {
                texture?.allocateTexture(width: Int(view.frame.width), height: Int(view.frame.height))
            }
            
            viewportSize.x = UInt32(texture!.width)
            viewportSize.y = UInt32(texture!.height)
            
            screenWidth = Float(texture!.width)
            screenHeight = Float(texture!.height)
            
            coreScissorRect = MTLScissorRect(x: 0, y: 0, width: texture!.texture.width, height: texture!.texture.height)
                        
            //if let map = currentMap?.map {
            //    map.setup(core: self)
            //}
            return true
        }
        return false
    }
    
    public func draw()
    {
        guard let drawable = view.currentDrawable else {
            return
        }
                
        if state == .Idle {
            startDrawing()
            
            if checkTexture() {
                //createPreview(asset, false)
            }
    
            let renderPassDescriptor = view.currentRenderPassDescriptor
            renderPassDescriptor?.colorAttachments[0].loadAction = .load
            let renderEncoder = coreCmdBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
            
            drawTexture(texture!.texture!, renderEncoder: renderEncoder!)
            renderEncoder?.endEncoding()
            
            coreCmdBuffer?.present(drawable)
            stopDrawing()

            return

        } else {
            //_Time.x += 1.0 / targetFPS
            //timeChanged.send(_Time.x)
        }
                
        if state == .Running {
            _Time.x += 1.0 / targetFPS
            _Frame += 1
        }
    }

    func startDrawing()
    {
        if coreCmdQueue == nil {
            coreCmdQueue = view.device!.makeCommandQueue()
        }
        coreCmdBuffer = coreCmdQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(deleteQueue: Bool = false)
    {
        coreCmdBuffer?.commit()
        coreCmdBuffer?.waitUntilCompleted()
        
        if deleteQueue {
            self.coreCmdQueue = nil
        }
        self.coreCmdBuffer = nil
    }
        
    /// Clears all local audio
    func clearLocalAudio()
    {
        for (_, a) in localAudioPlayers {
            a.stop()
        }
        localAudioPlayers = [:]
    }
    
    /// Clears all global audio
    func clearGlobalAudio()
    {
        for (_, a) in globalAudioPlayers {
            a.stop()
        }
        globalAudioPlayers = [:]
    }
    
    /// Updates the display once
    func updateOnce()
    {
        self.view.enableSetNeedsDisplay = true
        #if os(OSX)
        let nsrect : NSRect = NSRect(x:0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.setNeedsDisplay(nsrect)
        #else
        self.view.setNeedsDisplay()
        #endif
    }
    
    func drawTexture(_ texture: MTLTexture, renderEncoder: MTLRenderCommandEncoder)
    {
        let width : Float = Float(texture.width)
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
    }
    
    /// Creates vertex data for the given rectangle
    func createVertexData(texture: Texture2D, rect: MMRect) -> [Float]
    {
        let left: Float  = -texture.width / 2.0 + rect.x
        let right: Float = left + rect.width//self.width / 2 - x
        
        let top: Float = texture.height / 2.0 - rect.y
        let bottom: Float = top - rect.height

        let quadVertices: [Float] = [
            right, bottom, 1.0, 0.0,
            left, bottom, 0.0, 0.0,
            left, top, 0.0, 1.0,
            
            right, bottom, 1.0, 0.0,
            left, top, 0.0, 1.0,
            right, top, 1.0, 1.0,
        ]
        
        return quadVertices
    }
    
    /// Creates vertex data for the given rectangle
    func createVertexData(texture: MTLTexture, rect: MMRect) -> [Float]
    {
        let left: Float  = -Float(texture.width) / 2.0 + rect.x
        let right: Float = left + rect.width//self.width / 2 - x
        
        let top: Float = Float(texture.height) / 2.0 - rect.y
        let bottom: Float = top - rect.height

        let quadVertices: [Float] = [
            right, bottom, 1.0, 0.0,
            left, bottom, 0.0, 0.0,
            left, top, 0.0, 1.0,
            
            right, bottom, 1.0, 0.0,
            left, top, 0.0, 1.0,
            right, top, 1.0, 1.0,
        ]
        
        return quadVertices
    }
}
