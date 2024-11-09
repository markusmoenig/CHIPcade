//
//  Skin.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/11/24.
//

import SwiftUI

enum SkinItemType {
    case rect
    case text
    case register
    case flag
    case sprites
    case layers
}

class SkinItem {
    
    let type : SkinItemType
    var props: [String: Any] = [:]
        
    init(type: SkinItemType) {
        self.type = type
    }
    
}

class Skin {
    
    struct Parser {
        var previous: Token
        var current: Token
        var hadError: Bool
        var panicMode: Bool
    }
    
    var scanner: Scanner!
    var parser: Parser!
    var errors: Errors!
    
    var items : [SkinItem] = []
    
    var currSprite: Int = 0
    
    var markerArea: float4? = nil
    var markerWidth: Float = 0.0
    
    var currLayer: Int = 0

    var layerMarkerArea: float4? = nil
    var layerMarkerWidth: Float = 0.0
    
    init() {
    }
    
    func cursorMoved(pos: float2) {
        if let markerArea = markerArea {
            if pos.x > markerArea.x && pos.x - markerArea.x < markerArea.z {//}&& pos.y > markerArea.y && pos.y - markerArea.y < markerArea.w {
                let off = Int(Float(pos.x - markerArea.x) / markerWidth)
                currSprite = off
            } else {
                if pos.x < markerArea.x {
                    currSprite = 0
                }
            }
        }
        if let layerMarkerArea = layerMarkerArea {
            if pos.x > layerMarkerArea.x && pos.x - layerMarkerArea.x < layerMarkerArea.z {//}&& pos.y > markerArea.y && pos.y - markerArea.y < markerArea.w {
                let off = Int(Float(pos.x - layerMarkerArea.x) / layerMarkerWidth)
                currLayer = off
            } else {
                if pos.x < layerMarkerArea.x {
                    currLayer = 0
                }
            }
        }
    }
    
    /// Draw the skin
    func draw(draw2D: MetalDraw2D, game: Game) {
        let width = Float(draw2D.metalView.frame.width)
        //let height = Float(draw2D.metalView.frame.height)
        
        let offX = (width - 640) / 2

        draw2D.font = draw2D.fonts["squadaone"]

        for item in items {
            if item.type == .rect {
                if let pos = item.props["pos"] as? float2, let size = item.props["size"] as? float2 {
                    var rounding : Float = 0.0
                    var borderSize : Float = 0.0
                    var fillColor : float4 = .one
                    var borderColor : float4 = .one
                    var alpha : Float = 1.0
                    
                    if let round = item.props["rounding"] as? Float {
                        rounding = round
                    }
                    if let a = item.props["alpha"] as? Float {
                        alpha = a
                    }
                    if let bs = item.props["bordersize"] as? Float {
                        borderSize = bs
                    }
                    if let color = item.props["color"] as? float4 {
                        fillColor = color
                        fillColor.w *= alpha
                    }
                    if let color = item.props["bordercolor"] as? float4 {
                        borderColor = color
                        borderColor.w *= alpha
                    }
                    draw2D.drawBox(position: pos + float2(offX, 0), size: size, rounding: rounding, borderSize: borderSize, fillColor: fillColor, borderColor: borderColor)
                }
            } else
            if item.type == .sprites {
                if let pos = item.props["pos"] as? float2, let size = item.props["size"] as? float2 {
                    var rounding : Float = 0.0
                    var borderSize : Float = 0.0
                    var fillColor : float4 = .one
                    var borderColor : float4 = .one
                    var alpha : Float = 1.0
                    
                    if let round = item.props["rounding"] as? Float {
                        rounding = round
                    }
                    if let a = item.props["alpha"] as? Float {
                        alpha = a
                    }
                    if let bs = item.props["bordersize"] as? Float {
                        borderSize = bs
                    }
                    if let color = item.props["color"] as? float4 {
                        fillColor = color
                        fillColor.w *= alpha
                    }
                    if let color = item.props["bordercolor"] as? float4 {
                        borderColor = color
                        borderColor.w *= alpha
                    }
                    draw2D.drawBox(position: pos + float2(offX, 0), size: size, rounding: rounding, borderSize: borderSize, fillColor: fillColor, borderColor: borderColor)
                    
                    var onColor : float4 = .one
                    var offColor : float4 = .one

                    if let color = item.props["oncolor"] as? float4 {
                        onColor = color
                        onColor.w *= alpha
                    }
                    if let color = item.props["offcolor"] as? float4 {
                        offColor = color
                        offColor.w *= alpha
                    }
                    
                    // Markers
                    
                    var markerX = offX + pos.x + 15
                    let markerWidth = (size.x - 30.0) / 256.0
                    
                    if game.gcp.sprites.count == 256 {
                        for i in 0..<256 {
                            var color : float4 = offColor
                            
                            if game.gcp.sprites[i].isActive {
                                color = onColor
                            }
                            
                            draw2D.startShape()
                            draw2D.drawRect(markerX, pos.y + 8, markerWidth, 8.0, color)
                            draw2D.endShape()
                            markerX += markerWidth
                        }
                        
                        markerArea = float4(Float(offX) + pos.x + 15.0, pos.y + 8.0, Float(size.x - 30.0), pos.y + 20.0)
                        self.markerWidth = markerWidth
                        
                        // Text
                        
                        var textColor : float4 = .one
                        if let color = item.props["textcolor"] as? float4 {
                            textColor = color
                            textColor.w *= alpha
                        }
                        
                        draw2D.drawText(position: pos  + float2(offX + 15, 20), text: "Sprite \(currSprite): \(game.gcp.sprites[currSprite].isActive ? "Active" : "Inactive")", size: 15, color: textColor)
                     
                        if game.gcp.sprites[currSprite].isActive {
                            //var pos = float2(offX + 15, 20)
                            
                            draw2D.drawText(position: pos  + float2(offX + 120, 20), text: "X: \(String(Int(game.gcp.sprites[currSprite].position.x)))", size: 15, color: textColor)
                            
                            draw2D.drawText(position: pos  + float2(offX + 165, 20), text: "Y: \(String(Int(game.gcp.sprites[currSprite].position.y)))", size: 15, color: textColor)
                            
                            draw2D.drawText(
                                position: pos + float2(offX + 260, 20),
                                text: "Velocity: \(String(format: "%.3f", Float(game.gcp.sprites[currSprite].velocity.dx))), \(String(format: "%.3f", Float(game.gcp.sprites[currSprite].velocity.dy)))",
                                size: 15,
                                color: textColor
                            )
                            
                            draw2D.drawText(
                                position: pos + float2(offX + 120, 36),
                                text: "Size: \(String(format: "%.1f", Float(game.gcp.sprites[currSprite].size.width) * Float(game.gcp.sprites[currSprite].scale))) x \(String(format: "%.1f", Float(game.gcp.sprites[currSprite].size.height) * Float(game.gcp.sprites[currSprite].scale)))",
                                size: 15,
                                color: textColor
                            )
                            
                            draw2D.drawText(
                                position: pos + float2(offX + 120, 52),
                                text: "Rotation: \(String(format: "%.3f", Float(game.gcp.sprites[currSprite].rotation)))",
                                size: 15,
                                color: textColor
                            )
                        }
                    } else {
                        markerArea = nil
                    }
                }
            } else
            if item.type == .layers {
                if let pos = item.props["pos"] as? float2, let size = item.props["size"] as? float2 {
                    var rounding : Float = 0.0
                    var borderSize : Float = 0.0
                    var fillColor : float4 = .one
                    var borderColor : float4 = .one
                    var alpha : Float = 1.0
                    
                    if let round = item.props["rounding"] as? Float {
                        rounding = round
                    }
                    if let a = item.props["alpha"] as? Float {
                        alpha = a
                    }
                    if let bs = item.props["bordersize"] as? Float {
                        borderSize = bs
                    }
                    if let color = item.props["color"] as? float4 {
                        fillColor = color
                        fillColor.w *= alpha
                    }
                    if let color = item.props["bordercolor"] as? float4 {
                        borderColor = color
                        borderColor.w *= alpha
                    }
                    draw2D.drawBox(position: pos + float2(offX, 0), size: size, rounding: rounding, borderSize: borderSize, fillColor: fillColor, borderColor: borderColor)
                    
                    var onColor : float4 = .one
                    var offColor : float4 = .one

                    if let color = item.props["oncolor"] as? float4 {
                        onColor = color
                        onColor.w *= alpha
                    }
                    if let color = item.props["offcolor"] as? float4 {
                        offColor = color
                        offColor.w *= alpha
                    }
                    
                    // Markers
                    
                    var markerX = offX + pos.x + 20
                    let markerWidth = (size.x - 20.0) / 8.0
                    
                    if game.gcp.layers.count == 8 {
                        for i in 0..<7 {
                            var color : float4 = offColor
                            
                            if game.gcp.layers[i].isVisible {
                                color = onColor
                            }
                            
                            draw2D.startShape()
                            draw2D.drawRect(markerX, pos.y + 8, markerWidth, 8.0, color)
                            draw2D.endShape()
                            markerX += markerWidth
                        }
                        
                        layerMarkerArea = float4(Float(offX) + pos.x + 20.0, pos.y + 8.0, Float(size.x - 20.0), pos.y + 20.0)
                        self.layerMarkerWidth = markerWidth
                        
                        // Text
                        
                        var textColor : float4 = .one
                        if let color = item.props["textcolor"] as? float4 {
                            textColor = color
                            textColor.w *= alpha
                        }
                        
                        draw2D.drawText(position: pos  + float2(offX + 15, 20), text: "Layer \(currLayer): \(game.gcp.layers[currLayer].isVisible ? "Visible" : "Invisible")", size: 15, color: textColor)
                        
                        //if game.gcp.layers[currLayer].isVisible {
                            if let size = game.gcp.layers[currLayer].size {
                                draw2D.drawText(position: pos + float2(offX + 15, 36), text: "Custom (\(String(Int(size.width))) x \(String(Int(size.width))))", size: 15, color: textColor)
                            } else {
                                let width = Int(Game.shared.gcp.draw2D.metalView.frame.width)
                                let height = Int(Game.shared.gcp.draw2D.metalView.frame.height)
                                
                                draw2D.drawText(position: pos + float2(offX + 15, 36), text: "Screen (\(String(width)) x \(String(height))", size: 15, color: textColor)
                            }
                        //}
                    }
                }
            } else
            if item.type == .flag {
                if let pos = item.props["pos"] as? float2, let size = item.props["size"] as? float2 {
                    var rounding : Float = 0.0
                    var borderSize : Float = 0.0
                    var fillColor : float4 = .one
                    var borderColor : float4 = .one
                    var alpha : Float = 1.0
                    var name = ""
                    
                    if let n = item.props["name"] as? String {
                        name = n.lowercased()
                    }
                    if let round = item.props["rounding"] as? Float {
                        rounding = round
                    }
                    if let a = item.props["alpha"] as? Float {
                        alpha = a
                    }
                    if let bs = item.props["bordersize"] as? Float {
                        borderSize = bs
                    }
                    if let color = item.props["bordercolor"] as? float4 {
                        borderColor = color
                        borderColor.w *= alpha
                    }
                    
                    if name == "zf" {
                        if game.flags.zeroFlag {
                            if let color = item.props["oncolor"] as? float4 {
                                fillColor = color
                                fillColor.w *= alpha
                            }
                        } else
                       if let color = item.props["offcolor"] as? float4 {
                           fillColor = color
                           fillColor.w *= alpha
                       }
                    } else
                    if name == "cf" {
                        if game.flags.carryFlag {
                            if let color = item.props["oncolor"] as? float4 {
                                fillColor = color
                                fillColor.w *= alpha
                            }
                        } else
                       if let color = item.props["offcolor"] as? float4 {
                           fillColor = color
                           fillColor.w *= alpha
                       }
                    } else
                    if name == "of" {
                        if game.flags.overflowFlag {
                            if let color = item.props["oncolor"] as? float4 {
                                fillColor = color
                                fillColor.w *= alpha
                            }
                        } else
                       if let color = item.props["offcolor"] as? float4 {
                           fillColor = color
                           fillColor.w *= alpha
                       }
                    } else
                    if name == "nf" {
                        if game.flags.negativeFlag {
                            if let color = item.props["oncolor"] as? float4 {
                                fillColor = color
                                fillColor.w *= alpha
                            }
                        } else
                       if let color = item.props["offcolor"] as? float4 {
                           fillColor = color
                           fillColor.w *= alpha
                       }
                    }
                    
                    draw2D.drawBox(position: pos + float2(offX, 0), size: size, rounding: rounding, borderSize: borderSize, fillColor: fillColor, borderColor: borderColor)
                }
            } else
            if item.type == .text {
                if let pos = item.props["pos"] as? float2 {
                    var size : Float = 20.0
                    var fillColor : float4 = .one
                    var text : String = ""
                    var alpha : Float = 1.0
                    var rotated: Int = 0

                    if let fontsize = item.props["fontsize"] as? Float {
                        size = fontsize
                    }
                    if let rot = item.props["rotated"] as? Float {
                        rotated = Int(rot)
                    }
                    if let a = item.props["alpha"] as? Float {
                        alpha = a
                    }
                    if let color = item.props["color"] as? float4 {
                         fillColor = color
                        fillColor.w *= alpha
                    }
                    if let string = item.props["string"] as? String {
                         text = string
                    }
                    draw2D.drawText(position: pos  + float2(offX, 0), text: text, size: size, color: fillColor, rotated: rotated)
                }
            } else
            if item.type == .register {
                if let pos = item.props["pos"] as? float2 {
                    var size : Float = 20.0
                    var fillColor : float4 = .one
                    var text : String = ""
                    var alpha : Float = 1.0
                    //var minimized : Bool = false

                    if let fontsize = item.props["fontsize"] as? Float {
                        size = fontsize
                    }
                    if let a = item.props["alpha"] as? Float {
                        alpha = a
                    }
                    if let color = item.props["color"] as? float4 {
                        fillColor = color
                        fillColor.w *= alpha
                    }
                    if let index = item.props["index"] as? Float {
                        let ind = Int(index)
                        if ind < game.registers.count {
                            text = game.registers[ind].toStringFull(true)

//                            if full {
//                                text = game.registers[ind].toStringFull(true)
//                            } else {
//                                text = game.registers[ind].toString(true)
//                            }
                        }
                    }
                    draw2D.drawText(position: pos  + float2(offX, 0), text: text, size: size, color: fillColor)
                }
            }
        }
    }
        
    /// Compile the skin text
    func compile(text: String) {
        scanner = Scanner(text)
        errors = Errors()
                
        items = []
        
        parser = Parser(
            previous: Token(type: .eof, text: "", line: -1),
            current: Token(type: .eof, text: "", line: -1),
            hadError: false,
            panicMode: false
        )
        
        advance()
        while match(.eof) == false {
            
            let offset = scanner.current
            
            if check(.identifier) {
                
                //print(parser.current.type)
                
                // Check for top directives
                let lexeme = parser.current.lexeme.lowercased()
                //print(lexeme)
                
                if lexeme == "rect" {
                    items.append(SkinItem(type: .rect))
                    advance()
                } else
                if lexeme == "text" {
                    items.append(SkinItem(type: .text))
                    advance()
                } else
                if lexeme == "register" {
                    items.append(SkinItem(type: .register))
                    advance()
                } else
                if lexeme == "flag" {
                    items.append(SkinItem(type: .flag))
                    advance()
                } else
                if lexeme == "sprites" {
                    items.append(SkinItem(type: .sprites))
                    advance()
                } else
                if lexeme == "layers" {
                    items.append(SkinItem(type: .layers))
                    advance()
                }
                
                // Check for properties
                if let item = items.last {
                 
                    if lexeme == "pos" || lexeme == "position" {
                        advance()
                        item.props["pos"] = readFloat2()
                    } else
                    if lexeme == "size"  {
                        advance()
                        item.props["size"] = readFloat2()
                    } else
                        if lexeme == "width" || lexeme == "height" || lexeme == "rounding" || lexeme == "bordersize" || lexeme == "fontsize" || lexeme == "index" || lexeme == "alpha" || lexeme == "rotated" {
                        advance()
                        item.props[lexeme] = readFloat()
                    } else
                    if lexeme == "color" || lexeme == "bordercolor" || lexeme == "oncolor" || lexeme == "offcolor" || lexeme == "textcolor" {
                        advance()
                        item.props[lexeme] = readColor()
                    } else
                    if lexeme == "string" || lexeme == "name" {
                        advance()
                        item.props[lexeme] = readString()
                    }
                }
            }
            
            if offset == scanner.current {
                advance()
            }
        }
    }
    
    func readFloat2() -> float2 {
        var value : float2 = .zero
        if match(.equal) {
            if check(.number) {
                value.x = Float(parser.current.lexeme)!
                advance()
                if match(.comma) {
                    if check(.number) {
                        value.y = Float(parser.current.lexeme)!
                        advance()
                    }
                }
            }
        }
        return value
    }
    
    func readFloat() -> Float {
        var value : Float = .zero
        if match(.equal) {
            if check(.number) {
                value = Float(parser.current.lexeme)!
                advance()
            }
        }
        return value
    }
    
    func readString() -> String {
        var value : String = ""
        if match(.equal) {
            if check(.string) {
                value = parser.current.lexeme.replacingOccurrences(of: "\"", with: "")
                advance()
            }
        }
        return value
    }
    
    func readColor() -> float4 {
        var value: float4 = .one // Default color

        if match(.equal) {
            if check(.identifier) || check(.string) {
                let id = parser.current.lexeme.lowercased().replacingOccurrences(of: "\"", with: "")
                advance()
                
                // Convert named colors to float4
                switch id {
                case "black":
                    value = colorToFloat4(.black)
                case "blue":
                    value = colorToFloat4(.blue)
                case "brown":
                    value = colorToFloat4(.brown)
                case "cyan":
                    value = colorToFloat4(.cyan)
                case "gray":
                    value = colorToFloat4(.gray)
                case "green":
                    value = colorToFloat4(.green)
                case "indigo":
                    value = colorToFloat4(.indigo)
                case "mint":
                    value = colorToFloat4(.mint)
                case "orange":
                    value = colorToFloat4(.orange)
                case "pink":
                    value = colorToFloat4(.pink)
                case "purple":
                    value = colorToFloat4(.purple)
                case "red":
                    value = colorToFloat4(.red)
                case "teal":
                    value = colorToFloat4(.teal)
                case "white":
                    value = colorToFloat4(.white)
                case "yellow":
                    value = colorToFloat4(.yellow)
                case "clear":
                    value = float4(0, 0, 0, 0) // Fully transparent color
                case "accent":
                    value = colorToFloat4(.accentColor)
                case "primary":
                    value = colorToFloat4(.primary)
                case "secondary":
                    value = colorToFloat4(.secondary)
                default:
                    if let hexValue = Int(id, radix: 16) {
                        value = hexToFloat4(hexValue)
                        print(value)
                    }
                }
                
            }
//            else if check(.string) {
//                // Assume the number is a hexadecimal color code
//                print(parser.current.lexeme)
//                if let hexValue = Int(parser.current.lexeme, radix: 16) {
//                    value = hexToFloat4(hexValue)
//                    print(value)
//                }
//                advance()
//            }
        }
        return value
    }
    
    /// Consume the token if it is of the right value and advance, otherwise error out
    func consume(_ type: TokenType , _ message: String) {
        guard parser.current.type == type else {
            errorAtCurrent(message)
            return
        }

        advance()
    }
    
    /// Advance one token
    func advance() {
        parser.previous = parser.current
        
        while true {
            parser.current = scanner.scanToken()
            if parser.current.type != .error { break }
            
            errorAtCurrent(String(parser.current.lexeme))
        }
    }
    
    /// Advance if match
    func match(_ type: TokenType) -> Bool {
        if check(type) == false { return false }
        advance()
        return true
    }
    
    /// Check current token type
    func check(_ type: TokenType) -> Bool {
        return parser.current.type == type
    }
    
    func error(_ message: String) {
        errorAt(parser.previous, message)
    }
    
    func errorAtCurrent(_ message: String) {
        errorAt(parser.current, message)
    }
    
    func errorAt(_ token: Token, _ message: String) {
        guard !parser.panicMode else { return }
        parser.panicMode = true

        errors.add(token: token, message: message)
        
        parser.hadError = true
    }
    
    /// Convert SwiftUI color to float4
    func colorToFloat4(_ color: Color) -> float4 {
        #if os(iOS)
        // iOS uses UIColor
        let uiColor = UIColor(color) // Try to initialize directly from SwiftUI Color
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Ensure color is in RGB color space and extract the components
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        alpha = 1.0
        
        #elseif os(macOS)
        // macOS uses NSColor, convert it to sRGB space before extracting components
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white // Fallback to white if conversion fails
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return simd_float4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    /// Convert hex color to float4
    func hexToFloat4(_ hex: Int) -> float4 {
        let red, green, blue, alpha: Float
        
        if hex > 0xFFFFFF { // 4 components (RGBA)
            red = Float((hex >> 24) & 0xFF) / 255.0
            green = Float((hex >> 16) & 0xFF) / 255.0
            blue = Float((hex >> 8) & 0xFF) / 255.0
            alpha = Float(hex & 0xFF) / 255.0
        } else { // 3 components (RGB)
            red = Float((hex >> 16) & 0xFF) / 255.0
            green = Float((hex >> 8) & 0xFF) / 255.0
            blue = Float(hex & 0xFF) / 255.0
            alpha = 1.0
        }
        
        return float4(red, green, blue, alpha)
    }
}
