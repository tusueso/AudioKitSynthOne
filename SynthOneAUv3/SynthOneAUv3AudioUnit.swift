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
import AudioToolbox

class SynthOneAUv3AudioUnit: AUAudioUnit {

    private var _outputBusArray: AUAudioUnitBusArray!
    private var _internalRenderBlock: AUInternalRenderBlock!
    private var conductor: Conductor!

    var currentTempo = 0.0
    var transportStateIsMoving = false
    var mcb: AUHostMusicalContextBlock?
    var tsb: AUHostTransportStateBlock?
    var moeb: AUMIDIOutputEventBlock?


    override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {

        try super.init(componentDescription: componentDescription, options: options)


        self._internalRenderBlock = {[unowned self] (actionFlags, timeStamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock) in

            if renderEvent != nil {
                let head: AURenderEventHeader = renderEvent!.pointee.head
                if head.eventType == .parameter {
                    //let parameter: AUParameterEvent = renderEvent!.pointee.parameter
                } else if head.eventType == .parameterRamp {
                    //let parameter: AUParameterEvent = renderEvent!.pointee.parameter
                } else if head.eventType == .MIDI {
                    var MIDI: AUMIDIEvent? = renderEvent?.pointee.MIDI
                    while MIDI != nil {
                        let data = MIDI!.data
                        if MIDI!.eventType == AURenderEventType.MIDI { // might be redundant?
                            let statusByte = data.0 >> 4
                            let channel = data.0 & 0b0000_1111
                            let data1 = data.1 & 0b0111_1111
                            let data2 = data.2 & 0b0111_1111
                            if statusByte == 0b1000 {
                                // note off
                                Conductor.sharedInstance.synth.stop(noteNumber: data1) // add channel
                                NSLog("channel:%d, note off nn:%d", channel, data1)
                            } else if statusByte == 0b1001 {
                                // note on
                                Conductor.sharedInstance.synth.play(noteNumber: data1, velocity: data2) // add channel
                                NSLog("channel:%d, note on nn:%d, vel:%d", channel, data1, data2)
                            } else if statusByte == 0b1010 {
                                // poly key pressure
                                NSLog("channel:%d, poly key pressure nn:%d, p:%d", channel, data1, data2)
                            } else if statusByte == 0b1011 {
                                // controller change
                                NSLog("channel:%d, controller change cc:%d, value:%d", channel, data1, data2)
                            } else if statusByte == 0b1100 {
                                // program change
                                NSLog("channel:%d, program change preset #:%d", channel, data1)
                            } else if statusByte == 0b1101 {
                                // channel pressure
                                NSLog("channel:%d, channel pressure:%d", channel, data1)
                            } else if statusByte == 0b1110 {
                                // pitch bend
                                NSLog("channel:%d, pitch bend fine:%d, course:%d", channel, data1, data2)
                            }
                        }
                        MIDI = MIDI!.next?.pointee.MIDI
                    }
                } else if head.eventType == .midiSysEx {
                    //let MIDI: AUMIDIEvent = renderEvent!.pointee.MIDI
                }
            }


//            if renderEvent != nil {
//                let data = renderEvent!.pointee.MIDI.data
//                if renderEvent!.pointee.MIDI.eventType == AURenderEventType.MIDI {
//                    let status = data.0 & 0xf0
//                    let nn = data.1
//                    let v = data.2
//                    dump(data)
//                    dump(status)
//                    if status == 0x90 || status == 128 {
//                        Conductor.sharedInstance.synth.play(noteNumber: nn, velocity: v)
//                    }
//                    if status == 208 || status == 128 {
//                        if let note = renderEvent?.pointee.MIDI.next?.pointee.MIDI.data.1 {
//                            Conductor.sharedInstance.synth.stop(noteNumber: nn)
//                        }
//                    }
//                }
//            }

            // AUHostMusicalContextBlock
            // Block by which hosts provide musical tempo, time signature, and beat position
            if let mcb = self.mcb {
                var timeSignatureNumerator = 0.0
                var timeSignatureDenominator = 0
                var currentBeatPosition = 0.0
                var sampleOffsetToNextBeat = 0
                var currentMeasureDownbeatPosition = 0.0

                if mcb( &self.currentTempo, &timeSignatureNumerator, &timeSignatureDenominator, &currentBeatPosition, &sampleOffsetToNextBeat, &currentMeasureDownbeatPosition ) {
                    if let s = Conductor.sharedInstance.synth {
                        s.setSynthParameter(.arpRate, self.currentTempo)
                    }
//                    NSLog("current tempo %f", self.currentTempo)
//                    NSLog("timeSignatureNumerator %f", timeSignatureNumerator)
//                    NSLog("timeSignatureDenominator %ld", timeSignatureDenominator)

                    if self.transportStateIsMoving {
//                        NSLog("currentBeatPosition %f", currentBeatPosition);
//                        NSLog("sampleOffsetToNextBeat %ld", sampleOffsetToNextBeat);
//                        NSLog("currentMeasureDownbeatPosition %f", currentMeasureDownbeatPosition);
                    }
                }

            }

            // AUHostTransportStateBlock
            // Block by which hosts provide information about their transport state.
            if let tsb = self.tsb {
                var flags: AUHostTransportStateFlags = []
                var currentSamplePosition = 0.0
                var cycleStartBeatPosition = 0.0
                var cycleEndBeatPosition = 0.0

                if tsb(&flags, &currentSamplePosition, &cycleStartBeatPosition, &cycleEndBeatPosition) {

                    if flags.contains(AUHostTransportStateFlags.changed) {
//                        NSLog("AUHostTransportStateChanged bit set")
//                        NSLog("currentSamplePosition %f", currentSamplePosition)
                    }

                    if flags.contains(AUHostTransportStateFlags.moving) {
//                        NSLog("AUHostTransportStateMoving bit set");
//                        NSLog("currentSamplePosition %f", currentSamplePosition)

                        self.transportStateIsMoving = true

                    } else {
                        self.transportStateIsMoving = false
                    }

                    if flags.contains(AUHostTransportStateFlags.recording) {
//                        NSLog("AUHostTransportStateRecording bit set")
//                        NSLog("currentSamplePosition %f", currentSamplePosition)
                    }

                    if flags.contains(AUHostTransportStateFlags.cycling) {
//                        NSLog("AUHostTransportStateCycling bit set")
//                        NSLog("currentSamplePosition %f", currentSamplePosition)
//                        NSLog("cycleStartBeatPosition %f", cycleStartBeatPosition)
//                        NSLog("cycleEndBeatPosition %f", cycleEndBeatPosition)
                    }

                }
            }

            // AUMIDIOutputEventBlock
            //@brief        Block to provide MIDI output events to the host.
//            if let moeb = self.moeb {
//                NSLog("AUMIDIOutputEventBlock")
//            }

            _ = AudioKit.engine.manualRenderingBlock(frameCount, outputData, nil)

            return noErr
        }

        do {
            try AudioKit.engine.enableManualRenderingMode(.realtime, format: AudioKit.format, maximumFrameCount: 4_096)
            conductor = Conductor.sharedInstance
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
        return [1]
    }

    override var outputBusses: AUAudioUnitBusArray {
        return self._outputBusArray
    }


    override func allocateRenderResources() throws {
        do {
            try super.allocateRenderResources()
        } catch {
            return
        }

        self.mcb = self.musicalContextBlock
        self.tsb = self.transportStateBlock
        self.moeb = self.midiOutputEventBlock
    }

    override func deallocateRenderResources() {
        super.deallocateRenderResources()
        self.mcb = nil
        self.tsb = nil
        self.moeb = nil
    }

    override var internalRenderBlock: AUInternalRenderBlock {
        return self._internalRenderBlock
    }
}

