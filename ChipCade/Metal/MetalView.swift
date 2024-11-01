//
//  MetalView.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//


import SwiftUI
import MetalKit

public class ChipCadeView       : MTKView
{
    enum MetalViewType {
        case Game, CPU
    }
    
    var viewType            : MetalViewType = .Game
    
    var game                : Game!

    var keysDown            : [Float] = []
    
    var mouseIsDown         : Bool = false
    var mousePos            = float2(0, 0)
    
    var hasTap              : Bool = false
    var hasDoubleTap        : Bool = false
    
    var buttonDown          : String? = nil
    var swipeDirection      : String? = nil

    var commandIsDown       : Bool = false
    var shiftIsDown         : Bool = false
    
    func reset()
    {
        keysDown = []
        mouseIsDown = false
        hasTap  = false
        hasDoubleTap  = false
        buttonDown = nil
        swipeDirection = nil
    }

    #if os(OSX)
        
    override public var acceptsFirstResponder: Bool { return true }
    
    func platformInit()
    {
        layer?.isOpaque = false
    }
    
    func setMousePos(_ event: NSEvent)
    {
        var location = event.locationInWindow
        location.y = location.y - CGFloat(frame.height)
        location = convert(location, from: nil)
        
        mousePos.x = Float(location.x)
        mousePos.y = -Float(location.y)
        
        if viewType == .Game {
            Game.shared.registers[10] = .signed16Bit(Int16(location.x))
            Game.shared.registers[11] = .signed16Bit(Int16(-location.y))
            Game.shared.cpuRender.update()
        }
    }
    
    override public func keyDown(with event: NSEvent)
    {
        keysDown.append(Float(event.keyCode))
        
        if let characters = event.characters {
            for character in characters {
                if let asciiValue = character.asciiValue {
                    Game.shared.registers[8] = .unsigned16Bit(UInt16(asciiValue))
                }
            }
        } else {
            // Handle special non-character keys based on keyCode
            switch event.keyCode {
            case 123: // Left arrow
                Game.shared.registers[8] = .unsigned16Bit(128)
            case 126: // Up arrow
                Game.shared.registers[8] = .unsigned16Bit(129)
            case 124: // Right arrow
                Game.shared.registers[8] = .unsigned16Bit(130)
            case 125: // Down arrow
                Game.shared.registers[8] = .unsigned16Bit(131)

                // Function keys
            case 122: // F1
                Game.shared.registers[8] = .unsigned16Bit(132)
            case 120: // F2
                Game.shared.registers[8] = .unsigned16Bit(133)
            case 99:  // F3
                Game.shared.registers[8] = .unsigned16Bit(134)
            case 118: // F4
                Game.shared.registers[8] = .unsigned16Bit(135)
            case 96:  // F5
                Game.shared.registers[8] = .unsigned16Bit(136)
            case 97:  // F6
                Game.shared.registers[8] = .unsigned16Bit(137)
            case 98:  // F7
                Game.shared.registers[8] = .unsigned16Bit(138)
            case 100: // F8
                Game.shared.registers[8] = .unsigned16Bit(139)
            case 101: // F9
                Game.shared.registers[8] = .unsigned16Bit(140)
            case 109: // F10
                Game.shared.registers[8] = .unsigned16Bit(141)
            case 103: // F11
                Game.shared.registers[8] = .unsigned16Bit(142)
            case 111: // F12
                Game.shared.registers[8] = .unsigned16Bit(143)

                // Shift keys
            case 56: // Left Shift
                Game.shared.registers[8] = .unsigned16Bit(144)
            case 60: // Right Shift
                Game.shared.registers[8] = .unsigned16Bit(145)

            default: break
            }
        }
        Game.shared.cpuRender.update()
    }
    
    override public func keyUp(with event: NSEvent)
    {
        keysDown.removeAll{$0 == Float(event.keyCode)}
        Game.shared.registers[8] = .unsigned16Bit(0)
        Game.shared.cpuRender.update()
    }
        
    override public func mouseDown(with event: NSEvent) {
        setMousePos(event)
        if viewType == .Game {
            Game.shared.registers[9] = .unsigned16Bit(1)
            Game.shared.cpuRender.update()
        }
    }
    
    override public func mouseDragged(with event: NSEvent) {
        setMousePos(event)
        if viewType == .Game {
            Game.shared.registers[9] = .unsigned16Bit(2)
            Game.shared.cpuRender.update()
        }
    }
    
    override public func mouseUp(with event: NSEvent) {
        mouseIsDown = false
        hasTap = false
        hasDoubleTap = false
        setMousePos(event)
        if viewType == .Game {
            Game.shared.registers[9] = .unsigned16Bit(0)
            Game.shared.registers[10] = .signed16Bit(0)
            Game.shared.registers[11] = .signed16Bit(0)
            Game.shared.cpuRender.update()
        }
    }
    
    override public func scrollWheel(with event: NSEvent) {
        //core.nodesWidget.scrollWheel(float3(Float(event.deltaX), Float(event.deltaY), Float(event.deltaZ)))
    }
    
    override public func flagsChanged(with event: NSEvent) {
        //https://stackoverflow.com/questions/9268045/how-can-i-detect-that-the-shift-key-has-been-pressed
        if event.modifierFlags.contains(.shift) {
            shiftIsDown = true
        } else {
            shiftIsDown = false
        }
        
        if event.modifierFlags.contains(.command) {
            commandIsDown = true
        } else {
            commandIsDown = false
        }
    }
    
    #elseif os(iOS)
    
    func platformInit()
    {
        layer.isOpaque = false

        let tapRecognizer = UITapGestureRecognizer(target: self, action:(#selector(self.handleTapGesture(_:))))
        tapRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action:(#selector(self.handlePanGesture(_:))))
        panRecognizer.minimumNumberOfTouches = 2
        addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:(#selector(self.handlePinchGesture(_:))))
        addGestureRecognizer(pinchRecognizer)
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer)
    {
        if recognizer.numberOfTouches == 1 {
            hasTap = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60.0) {
                self.hasTap = false
            }
        } else
        if recognizer.numberOfTouches >= 1 {
            hasDoubleTap = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60.0) {
                self.hasDoubleTap = false
            }
        }
    }
    
    var lastX, lastY    : Float?
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer)
    {
        if recognizer.numberOfTouches > 1 {
            let translation = recognizer.translation(in: self)
            
            if ( recognizer.state == .began ) {
                lastX = 0
                lastY = 0
            }
            
            //let delta = float3(Float(translation.x) - lastX!, Float(translation.y) - lastY!, Float(recognizer.numberOfTouches))
            
            lastX = Float(translation.x)
            lastY = Float(translation.y)
            
//            core.nodesWidget.scrollWheel(delta)
        }
    }
    
    var firstTouch      : Bool = false
    @objc func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer)
    {
//        core.nodesWidget.pinchGesture(Float(recognizer.scale), firstTouch)
        firstTouch = false
    }
    
    func setMousePos(_ x: Float, _ y: Float)
    {
        mousePos.x = x
        mousePos.y = y
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        mouseIsDown = true
        firstTouch = true
        if let touch = touches.first {
            let point = touch.location(in: self)
            setMousePos(Float(point.x), Float(point.y))
//            core.nodesWidget.touchDown(mousePos)
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            setMousePos(Float(point.x), Float(point.y))
//            core.nodesWidget.touchMoved(mousePos)
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        mouseIsDown = false
        if let touch = touches.first {
            let point = touch.location(in: self)
            setMousePos(Float(point.x), Float(point.y))
//            core.nodesWidget.touchUp(mousePos)
        }
    }
    
    #elseif os(tvOS)
        
    func platformInit()
    {
        var swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeRecognizer.direction = .right
        addGestureRecognizer(swipeRecognizer)
        
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        swipeRecognizer.direction = .left
        addGestureRecognizer(swipeRecognizer)
        
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeRecognizer.direction = .up
        addGestureRecognizer(swipeRecognizer)
        
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeRecognizer.direction = .down
        addGestureRecognizer(swipeRecognizer)
    }
    
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        guard let buttonPress = presses.first?.type else { return }
            
        switch(buttonPress) {
            case .menu:
                buttonDown = "Menu"
            case .playPause:
                buttonDown = "Play/Pause"
            case .select:
                buttonDown = "Select"
            case .upArrow:
                buttonDown = "ArrowUp"
            case .downArrow:
                buttonDown = "ArrowDown"
            case .leftArrow:
                buttonDown = "ArrowLeft"
            case .rightArrow:
                buttonDown = "ArrowRight"
            default:
                print("Unkown Button", buttonPress)
        }
    }
    
    public override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        buttonDown = nil
    }
    
    @objc func swipedUp() {
       swipeDirection = "up"
    }
    
    @objc func swipedDown() {
       swipeDirection = "down"
    }
        
    @objc func swipedRight() {
       swipeDirection = "right"
    }
    
    @objc func swipedLeft() {
       swipeDirection = "left"
    }

    
    #endif
}

#if os(OSX)
struct MetalView: NSViewRepresentable {
    var game                : Game!
    var trackingArea        : NSTrackingArea?

    var viewType            : ChipCadeView.MetalViewType

    init(_ game: Game, _ viewType: ChipCadeView.MetalViewType)
    {
        self.game = game
        self.viewType = viewType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = ChipCadeView()
        mtkView.game = game
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        
        if viewType == .Game {
            game.gcp.setupView(mtkView)
        } else
        if viewType == .CPU {
            game.cpuRender.setupView(mtkView)
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()

        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//            if let mtkView = view as? ChipCadeView {
//                if parent.viewType == .Game {
//                    parent.game.gcp.setupView(mtkView)
//                }
//            }
        }
    
        
        func draw(in view: MTKView) {
            if parent.viewType == .Game {
                parent.game.drawGame()
            } else
            if parent.viewType == .CPU {
                parent.game.drawCPU()
            }
        }
    }
}
#else
struct MetalView: UIViewRepresentable {
    typealias UIViewType = MTKView
    var game             : Game!

    var viewType            : ChipCadeView.MetalViewType

    init(_ game: Game, _ viewType: ChipCadeView.MetalViewType)
    {
        self.game = game
        self.viewType = viewType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = ChipCadeView()
        mtkView.game = game
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
                
        if viewType == .Game {
            game.gcp.setupView(mtkView)
        } else
        if viewType == .CPU {
            game.cpuRender.setupView(mtkView)
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<MetalView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            if parent.viewType == .Game {
                parent.game.drawGame()
            } else
            if parent.viewType == .CPU {
                parent.game.drawCPU()
            }
        }
    }
}
#endif
