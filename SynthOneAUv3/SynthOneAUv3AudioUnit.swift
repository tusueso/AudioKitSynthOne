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

