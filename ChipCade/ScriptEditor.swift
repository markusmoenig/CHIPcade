//
//  ScriptEditor.swift
//  ChipCade
//
//  Created by Markus Moenig on 1/11/24.
//

struct CompileError
{
    var line            : Int32? = nil
    var column          : Int32? = 0
    var error           : String? = nil
    var type            : String = "error"
}

#if !os(tvOS)

import SwiftUI
@preconcurrency import WebKit
import Combine

class ScriptEditor
{
    var webView         : WKWebView
    var sessions        : Int = 0
    var colorScheme     : ColorScheme
    
    var helpText        : String = ""
    
    init(_ view: WKWebView,_ colorScheme: ColorScheme)
    {
        self.webView = view
        self.colorScheme = colorScheme
        
//        if let asset = core.assetFolder.current {
//            createSession(asset)
//            setTheme(colorScheme)
//        }
        
    }
    
    func setTheme(_ colorScheme: ColorScheme)
    {
        let theme: String
        if colorScheme == .light {
            theme = "tomorrow"
        } else {
            theme = "tomorrow_night"
        }
        webView.evaluateJavaScript(
            """
            editor.setTheme("ace/theme/\(theme)");
            """, completionHandler: { (value, error ) in
         })
    }
    
    /// Creates the main editor session
    func createSession(_ cb: (()->())? = nil)
    {
        sessions += 1
        webView.evaluateJavaScript(
            """
            var mainSession = ace.createEditSession(``)
            editor.setSession(mainSession)
            editor.session.setMode("ace/mode/chipcade");
            editor.setOption("firstLineNumber", 0)
            mainSession.setUseWrapMode(true);

            """, completionHandler: { (value, error ) in
                if let cb = cb {
                    cb()
                }
         })
        increaseFontSize()
    }
    
    func setReadOnly(_ readOnly: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setReadOnly(\(readOnly));
            """, completionHandler: { (value, error) in
         })
    }
    
    func decreaseFontSize()
    {
        webView.evaluateJavaScript(
            """
            var size = editor.getFontSize();
            size -= 1;
            size = Math.max(2, size);
            editor.setFontSize(size);
            """, completionHandler: { (value, error) in
         })
    }
    
    func increaseFontSize()
    {
        webView.evaluateJavaScript(
            """
            var size = editor.getFontSize();
            size += 1;
            editor.setFontSize(size);
            """, completionHandler: { (value, error) in
         })
    }
    
    func setSilentMode(_ silent: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setOptions({
                cursorStyle: \(silent ? "'wide'" : "'ace'") // "ace"|"slim"|"smooth"|"wide"
            });
            """, completionHandler: { (value, error) in
         })
    }
    
    /*
    func getAssetValue(_ asset: Asset,_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            \(asset.scriptName).getValue()
            """, completionHandler: { (value, error) in
                if let value = value as? String {
                    cb(value)
                }
         })
    }
    
    func setAssetValue(_ asset: Asset, value: String)
    {
        let cmd = """
        \(asset.scriptName).setValue(`\(value)`)
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setAssetSession(_ asset: Asset)
    {
        core.showingHelp = false
        func setSession()
        {
            let cmd = """
            editor.setSession(\(asset.scriptName))
            """
            webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
            })
        }
        
        if asset.scriptName.isEmpty == true {
            createSession(asset, { () in
                setSession()
            })
        } else {
            setSession()
        }

    }*/
    
    func setError(_ error: CompileError, scrollToError: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations([{
            row: \(error.line!-1),
            column: \(error.column!),
            text: "\(error.error!)",
            type: "error" // also warning and information
            }]);

            \(scrollToError == true ? "editor.scrollToLine(\(error.line!-1), true, true, function () {});" : "")

            """, completionHandler: { (value, error ) in
         })
    }
    
    func setErrors(_ errors: [CompileError])
    {
        var str = "["
        for error in errors {
            str +=
            """
            {
                row: \(error.line!),
                column: \(error.column!),
                text: \"\(error.error!)\",
                type: \"\(error.type)\"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setFailures(_ lines: [Int32])
    {
        var str = "["
        for line in lines {
            str +=
            """
            {
                row: \(line),
                column: 0,
                text: "Failed",
                type: "error"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func getSessionCursor()
    {
        webView.evaluateJavaScript(
            """
            editor.getCursorPosition().row
            """, completionHandler: { (value, error ) in
                if let v = value as? Int {
                    Game.shared.codeLineChanged.send(v)
                }
         })
    }
    
    func getChangeDelta(_ cb: @escaping (Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            delta
            """, completionHandler: { (value, error ) in
                //print(value)
                if let map = value as? [String:Any] {
                    var from : Int32 = -1
                    var to   : Int32 = -1
                    if let f = map["start"] as? [String:Any] {
                        if let ff = f["row"] as? Int32 {
                            from = ff
                        }
                    }
                    if let t = map["end"] as? [String:Any] {
                        if let tt = t["row"] as? Int32 {
                            to = tt
                        }
                    }
                    cb(from, to)
                }
         })
    }
    
    func clearAnnotations()
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().clearAnnotations()
            """, completionHandler: { (value, error ) in
         })
    }
    
    func getSessionValue(_ session: String,_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            editor.getValue()
            """, completionHandler: { (value, error) in
                if let value = value as? String {
                    cb(value)
                }
         })
    }
    
    func setSession(_ session: String)
    {
        print("set session \(session)")
        let cmd = """
        editor.setSession(\(session))
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setSessionValue(_ session: String,_ value: String, _ line: Int)
    {
        let cmd : String
        
        if !Game.shared.skinMode {
            cmd = """
            \(session).setValue(`\(value)`)
            \(session).setMode("ace/mode/chipcade");
            editor.moveCursorTo(\(line), 0);
            editor.gotoLine(\(line))
            """
        } else {
            cmd = """
            \(session).setValue(`\(value)`)
            \(session).setMode("ace/mode/chipcade_skin");
            editor.moveCursorTo(\(line), 0);
            editor.gotoLine(\(line))
            """
        }

        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func sessionGotoLine(_ session: String,_ line: Int)
    {
        let cmd = """
        editor.moveCursorTo(\(line), 0);        
        editor.gotoLine(\(line))
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    /// Script has changed
    func updated()
    {
        if !Game.shared.skinMode {
            getSessionValue("mainSession", { (value) in
                Game.shared.currentCodeItemText = value
                Game.shared.codeTextChanged.send()
            })
        } else {
            getSessionValue("mainSession", { (value) in
                Game.shared.data.skin = value
                Game.shared.codeTextChanged.send()
            })
        }
    }
}

class WebViewModel: ObservableObject {
    @Published var didFinishLoading: Bool = false
    
    init () {
    }
}

#if os(OSX)
struct SwiftUIWebView: NSViewRepresentable {
    public typealias NSViewType = WKWebView
    var colorScheme : ColorScheme

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {//}, subdirectory: "Files") {
            webView.isHidden = false
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private var colorScheme : ColorScheme

        init(_ colorScheme: ColorScheme) {
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = Game.shared.scriptEditor {
                    //scriptEditor.updated()
                    if let action = message.body as? String {
                        switch action {
                        case "update":
                            scriptEditor.updated()
                        case "cursorChanged":
                            scriptEditor.getSessionCursor();
                        default:
                            print("Unknown action received: \(action)")
                        }
                    }
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
            Game.shared.scriptEditor = ScriptEditor(webView, colorScheme)
            if let editor = Game.shared.scriptEditor {
                if editor.sessions == 0 {
                    editor.createSession()
                    webView.allowsLinkPreview = true
                    
                    if let editor = Game.shared.scriptEditor {
                        if Game.shared.skinMode == false {
                            if let codeItem = Game.shared.getCodeItem() {
                                editor.setSessionValue("mainSession",  Game.shared.currentCodeItemText, codeItem.currLine)
                            }
                        } else {
                            editor.setSessionValue("mainSession",  Game.shared.data.skin, 0)
                        }
                    }
                }
            }
            webView.isHidden = false
        }
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
#else
struct SwiftUIWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    var colorScheme : ColorScheme
    
    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private var colorScheme : ColorScheme
        
        init(_ colorScheme: ColorScheme) {
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//            if message.name == "jsHandler" {
//                if let scriptEditor = core.scriptEditor {
//                    scriptEditor.updated()
//                }
//            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
            Game.shared.scriptEditor = ScriptEditor(webView, colorScheme)
            if let editor = Game.shared.scriptEditor {
                if editor.sessions == 0 {
                    editor.createSession()
                    webView.allowsLinkPreview = true
                    
                    if let editor = Game.shared.scriptEditor {
                        if Game.shared.skinMode == false {
                            if let codeItem = Game.shared.getCodeItem() {
                                editor.setSessionValue("mainSession",  Game.shared.currentCodeItemText, codeItem.currLine)
                            }
                        } else {
                            editor.setSessionValue("mainSession",  Game.shared.data.skin, 0)
                        }
                    }
                }
            }
            webView.isHidden = false        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct WebView  : View {
    var colorScheme : ColorScheme

    init(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        SwiftUIWebView(colorScheme: colorScheme)
    }
}

#else

class ScriptEditor
{
    var mapHelpText     : String = "## Available:\n\n"
    var behaviorHelpText: String = "## Available:\n\n"
    
    func createSession(_ asset: Asset,_ cb: (()->())? = nil) {}
    
    func setAssetValue(_ asset: Asset, value: String) {}
    func setAssetSession(_ asset: Asset) {}
    
    func setError(_ error: CompileError, scrollToError: Bool = false) {}
    func setErrors(_ errors: [CompileError]) {}
    func clearAnnotations() {}
    
    func getSessionCursor(_ cb: @escaping (Int32)->() ) {}
    
    func setReadOnly(_ readOnly: Bool = false) {}
    func setDebugText(text: String) {}
    
    func setFailures(_ lines: [Int32]) {}
    
    func getBehaviorHelpForKey(_ key: String) -> String? { return nil }
    func getMapHelpForKey(_ key: String) -> String? { return nil }
}

#endif
