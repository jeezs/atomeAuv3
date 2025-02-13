//
//  AppDelegate.swift
//  webview
//
//  Created by jeezs on 26/04/2022.
//


import SwiftUI

@main
struct atomeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        WebViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}
