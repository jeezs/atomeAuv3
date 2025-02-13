//
//  AudioUnitViewController.swift
//  atome
//
//  Created by jeezs on 12/02/2022.
//

import CoreAudioKit
import WebKit


public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    @IBOutlet var webView: WKWebView!


    
    public override func viewDidLoad() {
        super.viewDidLoad()
  
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        WebViewManager.setupWebView(for: webView)
    }

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try auv3Utils(componentDescription: componentDescription, options: [])
        return audioUnit!
    }

    func getHostSampleRate() -> Double? {
        guard let au = audioUnit, au.outputBusses.count > 0 else {
            print("No output busses available")
            return nil
        }
        return au.outputBusses[0].format.sampleRate
    }
}


