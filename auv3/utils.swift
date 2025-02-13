////
////  utils.swift
////  atome
////
////  Created by jeezs on 26/04/2022.
////


import AVFoundation

public class auv3Utils: AUAudioUnit {
    private var _outputBusArray: AUAudioUnitBusArray!
    private var _inputBusArray: AUAudioUnitBusArray!

    override public var inputBusses: AUAudioUnitBusArray {
        return _inputBusArray
    }

    override public var outputBusses: AUAudioUnitBusArray {
        return _outputBusArray
    }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)

        // Create the audio bus arrays
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        _inputBusArray = AUAudioUnitBusArray(audioUnit: self,
                                             busType: .input,
                                             busses: [try AUAudioUnitBus(format: format)])

        _outputBusArray = AUAudioUnitBusArray(audioUnit: self,
                                              busType: .output,
                                              busses: [try AUAudioUnitBus(format: format)])
    }

//    public override var internalRenderBlock: AUInternalRenderBlock {
//        return { [weak self] actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in
//            guard let self = self else { return noErr }
//
//            self.checkHostTransport()
//            self.checkHostTempo()  // Ajout de la vérification du tempo
//
//            return noErr
//        }
//    }
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in

            guard let pullInputBlock = pullInputBlock else {
                return kAudioUnitErr_NoConnection
            }

            var inputTimestamp = AudioTimeStamp()
            let inputBusNumber: Int = 0 // Utilisation d'un entier simple

            // Récupération des données audio d'entrée
            let inputStatus = pullInputBlock(actionFlags, &inputTimestamp, frameCount, inputBusNumber, outputData)

            if inputStatus != noErr {
                return inputStatus
            }

            // Copie du buffer d'entrée vers la sortie
            let numBuffers = Int(outputData.pointee.mNumberBuffers)
            for _ in 0..<numBuffers {
                let inBuffer = outputData.pointee.mBuffers // Utilisation correcte
                let outBuffer = outputData.pointee.mBuffers
                memcpy(outBuffer.mData, inBuffer.mData, Int(inBuffer.mDataByteSize))
            }

            return noErr
        }
    }

    public override var musicalContextBlock: AUHostMusicalContextBlock? {
        get {
            return super.musicalContextBlock
        }
        set {
            super.musicalContextBlock = newValue
        }
    }

    private func checkHostTransport() {
        if let transportStateBlock = self.transportStateBlock {
            var transportStateChanged = AUHostTransportStateFlags(rawValue: 0)
            var currentSampleTime: Double = 0

            let success = transportStateBlock(&transportStateChanged,
                                          &currentSampleTime,
                                          nil,
                                          nil)
            if success {
                DispatchQueue.main.async {
                    if transportStateChanged.rawValue != 0 {
                        if transportStateChanged.rawValue & 2 != 0 {
                            print("Transport is playing")
                        }
                        print("Playhead position: \(currentSampleTime)")
                        
                        if let sampleRate = self.getSampleRate() {
                            print("Sample Rate: \(sampleRate)")
                        }
                    }
                }
            } else {
                print("Failed to retrieve transport state")
            }
        }
    }
  
    
    
    private func checkHostTempo() {
        guard let contextBlock = self.musicalContextBlock else {
            print("No musical context block available")
            return
        }

        var tempo: Double = 0
        var timeSignatureNumerator: Double = 0
        var timeSignatureDenominator: Int = 0
        var currentBeatPosition: Double = 0
        var timeSignatureValid: Int = 0
        var tempoValid: Double = 0

        let success = contextBlock(
            &tempo,
            &timeSignatureNumerator,
            &timeSignatureDenominator,
            &currentBeatPosition,
            &timeSignatureValid,
            &tempoValid
        )

        if success {
            if timeSignatureValid != 0 {
                print("Tempo: \(tempo) BPM") // Correction ici
                print("Time Signature: \(Int(timeSignatureNumerator))/\(Int(timeSignatureDenominator))") // Correction ici
                print("Beat Position: \(currentBeatPosition)")
            }
        }
    }

    
    // Sample rate retrieval method
    func getSampleRate() -> Double? {
        guard outputBusses.count > 0 else {
            print("No output busses available")
            return nil
        }
        return outputBusses[0].format.sampleRate
    }
}
