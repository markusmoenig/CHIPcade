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
    
    init() {
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
            if item.type == .text {
                if let pos = item.props["pos"] as? float2 {
                    var size : Float = 20.0
                    var fillColor : float4 = .one
                    var text : String = ""
                    var alpha : Float = 1.0

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
                    if let string = item.props["string"] as? String {
                         text = string
                    }
                    draw2D.drawText(position: pos  + float2(offX, 0), text: text, size: size, color: fillColor)
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
                        if lexeme == "width" || lexeme == "height" || lexeme == "rounding" || lexeme == "bordersize" || lexeme == "fontsize" || lexeme == "index" || lexeme == "alpha" {
                        advance()
                        item.props[lexeme] = readFloat()
                    } else
                    if lexeme == "color" || lexeme == "bordercolor" {
                        advance()
                        item.props[lexeme] = readColor()
                    } else
                    if lexeme == "string" {
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
