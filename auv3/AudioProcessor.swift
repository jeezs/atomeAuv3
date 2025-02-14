import AVFoundation
import WebKit

class AudioProcessor: NSObject {
    static let shared = AudioProcessor()
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var jsAudioBuffer: [Float] = []
    private let bufferSize = 4096
    
    override init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func processAudioBlock(_ bufferList: UnsafeMutablePointer<AudioBufferList>, frameCount: UInt32) {
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        guard let firstBuffer = buffers.first else { return }
        
        guard let audioData = firstBuffer.mData else { return }
        let samples = UnsafeMutableBufferPointer<Float32>(
            start: audioData.assumingMemoryBound(to: Float32.self),
            count: Int(frameCount)
        )
        
        let samplesArray = Array(samples)
        
        DispatchQueue.main.async {
            WebViewManager.sendToJS(samplesArray, "processAudioData")
        }
    }
    
    func processAudioFromJS(samples: [Float]) {
        jsAudioBuffer.append(contentsOf: samples)
        
        while jsAudioBuffer.count >= bufferSize {
            let bufferData = Array(jsAudioBuffer.prefix(bufferSize))
            jsAudioBuffer.removeFirst(bufferSize)
            
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(bufferSize)) else { return }
            
            for channel in 0..<2 {
                guard let channelData = buffer.floatChannelData?[channel] else { continue }
                for i in 0..<bufferSize {
                    channelData[i] = bufferData[i]
                }
            }
            buffer.frameLength = AVAudioFrameCount(bufferSize)
            
            playerNode.scheduleBuffer(buffer, completionHandler: nil)
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }
    }
}

// Custom subclass to override the internalRenderBlock getter
class CustomAuv3Utils: auv3Utils {
    override var internalRenderBlock: AUInternalRenderBlock {
        let originalBlock = super.internalRenderBlock
        return { actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in
            let status = originalBlock(actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock)
            if status == noErr {
                AudioProcessor.shared.processAudioBlock(outputData, frameCount: frameCount)
            }
            return status
        }
    }
}

// Extension for AudioUnitViewController
extension AudioUnitViewController: WKScriptMessageHandler {
    public func setupAudioRouting() {
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "audiobridge")
        
        if let auv3 = audioUnit as? CustomAuv3Utils { 
            _ = auv3.internalRenderBlock
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "audiobridge" {
            if let body = message.body as? [String: Any],
               let type = body["type"] as? String,
               let data = body["data"] as? [Float],
               type == "audio" {
                AudioProcessor.shared.processAudioFromJS(samples: data)
            }
        }
    }
}
