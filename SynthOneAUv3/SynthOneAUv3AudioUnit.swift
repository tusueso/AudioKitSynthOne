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

class SwiftSynthOneAUv3AudioUnit: AUAudioUnit {

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

            // note that "self" is captured many times throughout this block definition
            self._internalRenderBlock = {[unowned self] (actionFlags, timeStamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock) in

            var renderEvent: UnsafePointer<AURenderEvent>? = UnsafePointer(renderEvent)
            while renderEvent != nil {
                let head: AURenderEventHeader = renderEvent!.pointee.head
                if head.eventType == .parameter {
                    //let parameter: AUParameterEvent = renderEvent!.pointee.parameter
                } else if head.eventType == .parameterRamp {
                    //let parameter: AUParameterEvent = renderEvent!.pointee.parameter
                } else if head.eventType == .MIDI {
                    let MIDI: AUMIDIEvent = renderEvent!.pointee.MIDI
                    let data = MIDI.data
                    let statusByte = data.0 >> 4
                    let channel = data.0 & 0b0000_1111
                    let data1 = data.1 & 0b0111_1111
                    let data2 = data.2 & 0b0111_1111
                    if statusByte == 0b1000 {
                        // note off
                        Conductor.sharedInstance.stop(channel: channel, noteNumber: data1)
                        NSLog("channel:%d, note off nn:%d", channel, data1)
                    } else if statusByte == 0b1001 {
                        if data2 > 0 {
                            // note on
                            NSLog("channel:%d, note on nn:%d, vel:%d", channel, data1, data2)
                            Conductor.sharedInstance.play(channel: channel, noteNumber: data1, velocity: data2)
                        } else {
                            // note off
                            NSLog("channel:%d, note off nn:%d", channel, data1)
                            Conductor.sharedInstance.stop(channel: channel, noteNumber: data1)
                        }
                    } else if statusByte == 0b1010 {
                        // poly key pressure
                        NSLog("channel:%d, poly key pressure nn:%d, p:%d", channel, data1, data2)
                        Conductor.sharedInstance.polyKeyPressure(channel: channel, noteNumber: data1, pressure: data2)
                    } else if statusByte == 0b1011 {
                        // controller change
                        NSLog("channel:%d, controller change cc:%d, value:%d", channel, data1, data2)
                        Conductor.sharedInstance.controllerChange(channel: channel, cc: data1, value: data2)
                    } else if statusByte == 0b1100 {
                        // program change
                        NSLog("channel:%d, program change preset #:%d", channel, data1)
                        Conductor.sharedInstance.programChange(channel: channel, preset: data1)
                    } else if statusByte == 0b1101 {
                        // channel pressure
                        NSLog("channel:%d, channel pressure:%d", channel, data1)
                        Conductor.sharedInstance.channelPressure(channel: channel, pressure: data1)
                    } else if statusByte == 0b1110 {
                        // pitch bend
                        let pb = UInt16(data2) << 7 + UInt16(data1)
                        NSLog("channel:%d, pitch bend fine:%d, course:%d, pb:%d", channel, data1, data2, pb)
                        Conductor.sharedInstance.pitchBend(channel: channel, amount: pb)
                    }
                } else if head.eventType == .midiSysEx {
                    //let MIDI: AUMIDIEvent = renderEvent!.pointee.MIDI
                }

                renderEvent = UnsafePointer(renderEvent?.pointee.head.next)
            }

            // AUHostMusicalContextBlock
            // Block by which hosts provide musical tempo, time signature, and beat position
            if let mcb = self.mcb {
                var timeSignatureNumerator = 0.0
                var timeSignatureDenominator = 0
                var currentBeatPosition = 0.0
                var sampleOffsetToNextBeat = 0
                var currentMeasureDownbeatPosition = 0.0

                if mcb( &self.currentTempo, &timeSignatureNumerator, &timeSignatureDenominator, &currentBeatPosition, &sampleOffsetToNextBeat, &currentMeasureDownbeatPosition ) {
                    Conductor.sharedInstance.setSynthParameter(.arpRate, self.currentTempo)
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
        return [0, 1, 2]
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

