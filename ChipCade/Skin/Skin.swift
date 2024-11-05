//
//  Skin.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/11/24.
//

enum SkinItemType {
    case rect
    
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
        //let width = Float(draw2D.metalView.frame.width)
        //let height = Float(draw2D.metalView.frame.height)
        
        for item in items {
            if item.type == .rect {
                print(item.props)
                if let pos = item.props["pos"] as? float2, let size = item.props["size"] as? float2 {
                    var rounding : Float = 0.0
                    if let round = item.props["rounding"] as? Float {
                        rounding = round
                    }
                    draw2D.drawBox(position: pos, size: size, rounding: rounding)
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
                    if lexeme == "width" {
                        advance()
                        item.props["width"] = readFloat()
                    } else
                    if lexeme == "height" {
                        advance()
                        item.props["height"] = readFloat()
                    } else
                    if lexeme == "rounding" {
                        advance()
                        item.props["rounding"] = readFloat()
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
}
