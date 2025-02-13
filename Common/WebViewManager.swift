//
//  WebViewManager.swift
//  atome
//
//  Created by jeezs on 26/04/2022.
//


import WebKit

class WebViewManager {
 
    static func setupWebView(for webView: WKWebView) {
        print("webview initialzed")
        let myProjectBundle: Bundle = Bundle.main
        if let myUrl = myProjectBundle.url(forResource: "view/index", withExtension: "html") {
            webView.loadFileURL(myUrl, allowingReadAccessTo: myUrl)
        } else {
            print("Error: Could not find index.html in bundle.")
        }
    }
}
