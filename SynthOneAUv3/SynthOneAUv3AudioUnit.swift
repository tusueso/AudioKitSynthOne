//
//  SynthOneAUv3AudioUnit.swift
//  SynthOneAUv3
//
//  Created by Aurelius Prochazka on 9/16/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import AVFoundation
import AudioKit
import CoreAudioKit

class SynthOneAUv3AudioUnit: AUAudioUnit {

    private var _outputBusArray: AUAudioUnitBusArray!
    private var _internalRenderBlock: AUInternalRenderBlock!
    private var conductor: Conductor!

    override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {

        self._internalRenderBlock = { (actionFlags, timeStamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock) in
            if renderEvent != nil {

                let data = renderEvent!.pointee.MIDI.data

                if renderEvent!.pointee.MIDI.eventType == AURenderEventType.MIDI {
                    let status = data.0 & 0xf0
                    let nn = data.1
                    let v = data.2
                    dump(data)
                    dump(status)
                    if status == 0x90 || status == 128 {
                        Conductor.sharedInstance.synth.play(noteNumber: nn, velocity: v)
                        //Conductor.sharedInstance.receivedMIDINoteOn(noteNumber: nn, velocity: v, channel: 0)
                    }
                    if status == 208 || status == 128 {
                        if let note = renderEvent?.pointee.MIDI.next?.pointee.MIDI.data.1 {
                            Conductor.sharedInstance.synth.stopAllNotes()
                            //Conductor.sharedInstance.receivedMIDINoteOff(noteNumber: note, velocity: 0, channel: 0)
                        }
                    }

                }
            }
            _ = AudioKit.engine.manualRenderingBlock(frameCount, outputData, nil)

            return noErr
        }

        do {
            try AudioKit.engine.enableManualRenderingMode(.realtime, format: AudioKit.format, maximumFrameCount: 4_096)
            conductor = Conductor.sharedInstance
//            conductor.start()

            try super.init(componentDescription: componentDescription, options: options)
            let bus = try AUAudioUnitBus(format: AudioKit.format)
            self._outputBusArray = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [bus])
        } catch {
            throw error
        }
    }
    override func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
        for configuration in availableViewConfigurations {
            print("width ", configuration.width)
            print("height ", configuration.height)
            print("has controller ", configuration.hostHasController)
            print("")
        }
        return [0, 1, 2]
    }

    override var outputBusses: AUAudioUnitBusArray {
        return self._outputBusArray
    }

    override var internalRenderBlock: AUInternalRenderBlock {
        return self._internalRenderBlock
    }
}

