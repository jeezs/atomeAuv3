//
//  WebViewManager.swift
//  Common
//
//  Created by jeezs on 26/04/2022.
//

import Foundation
import WebKit

public class WebViewManager: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    public static let shared = WebViewManager()
    public static var webView: WKWebView?
    
    public static func setupWebView(for webView: WKWebView) {
    
        self.webView = webView
        webView.navigationDelegate = WebViewManager.shared

        let scriptSource = """
        window.onerror = function(m, s, l, c, e) {
            var msg = "Error: " + m + " at " + s + ":" + l + ":" + c + (e && e.stack ? " stack: " + e.stack : "");
            try {
                window.webkit.messageHandlers.console.postMessage(msg);
            } catch(x) {
                console.warn("Error sending to Swift:", x);
            }
        };
        window.addEventListener("unhandledrejection", function(e) {
            var msg = "Unhandled Promise: " + e.reason + (e.reason && e.reason.stack ? " stack: " + e.reason.stack : "");
            try {
                window.webkit.messageHandlers.console.postMessage(msg);
            } catch(x) {
                console.warn("Error sending to Swift:", x);
            }
        });
        console.log("JavaScript loaded successfully!");
        """

        let contentController = webView.configuration.userContentController
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        contentController.add(WebViewManager.shared, name: "console")
        contentController.add(WebViewManager.shared, name: "swiftBridge")

        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        print("webview initialized")
        
        let myProjectBundle: Bundle = Bundle.main
        if let myUrl = myProjectBundle.url(forResource: "view/index", withExtension: "html") {
            webView.loadFileURL(myUrl, allowingReadAccessTo: myUrl)
        } else {
            print("Error: Could not find index.html in bundle.")
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "console":
            if let messageBody = message.body as? String {
                print("WebView Log: \(messageBody)")
            }
            
        case "swiftBridge":
            if let body = message.body as? [String: Any],
               let type = body["type"] as? String,
               let data = body["data"] {
                handleSwiftBridgeMessage(type: type, data: data)
            }
            
        default:
            break
        }
    }
    
    private func handleSwiftBridgeMessage(type: String, data: Any) {
        switch type {
        case "log":
            if let message = data as? String {
                print("JS Log: \(message)")
            } else {
                print("JS Log: \(data)")
            }
            
        case "my_swit_method":
            if let userData = data as? [String: String],
               let user = userData["user"],
               let action = userData["action"] {
                handleUserAction(user: user, action: action)
            }
            
        case "performCalculation":
            if let numbers = data as? [Int] {
                performCalculation(numbers)
            }
            
        case "saveData":
            if let errorMessage = data as? String {
                handleError(message: errorMessage)
            }
            
        default:
            print("Message reçu non géré - Type: \(type), Data: \(data)")
        }
    }
    
    public static func sendToJS(_ message: Any, _ function: String) {
        var jsValue: String

        if let stringValue = message as? String {
             jsValue = "\"" + stringValue.replacingOccurrences(of: "\"", with: "\\\"") + "\""
         } else if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
             jsValue = jsonString
         } else {
             jsValue = "\(message)"
         }

         let jsCode = """
         if (typeof \(function) === 'function') {
             console.log("\(function) is defined, calling it with:", \(jsValue));
             \(function)(\(jsValue));
         } else {
             console.error("\(function) is not defined!");
         }
         """

        webView?.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("JS Error (\(function)): \(error.localizedDescription)")
            } else {
                print("JS Executed (\(function)): \(String(describing: result))")
            }
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page web chargée avec succès")
        WebViewManager.sendToJS("test", "creerDivRouge")
    }
    
    private func handleUserAction(user: String, action: String) {
        // Implémentation vide
    }
    
    private func performCalculation(_ numbers: [Int]) {
        print("Calcul avec les nombres: \(numbers)")
    }
    
    public func handleError(message: String) {
        print("Erreur reçue: \(message)")
    }
}
