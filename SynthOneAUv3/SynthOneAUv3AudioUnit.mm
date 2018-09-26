//
//  SynthOneAUv3AudioUnit.m
//  SynthOneAUv3
//
//  Created by Aurelius Prochazka on 9/22/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#import "SynthOneAUv3AudioUnit.h"
#import <AudioKit/AudioKit-swift.h>
#import <SynthOneAUv3-Swift.h>
#import <AVFoundation/AVFoundation.h>
#import "S1DSPKernel.hpp"

// Define parameter addresses.
const AudioUnitParameterID myParam1 = 0;

@interface SynthOneAUv3AudioUnit ()
{
    AUAudioUnitBusArray* _inputBusArray;
    AUAudioUnitBusArray* _outputBusArray;
    AUHostMusicalContextBlock _musicalContextBlock;
    AUMIDIOutputEventBlock _outputEventBlock;
    AUHostTransportStateBlock _transportStateBlock;
    S1DSPKernel* _kernelPtr;
}
@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@end


@implementation SynthOneAUv3AudioUnit

@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];

    if (self == nil) {
        return nil;
    }

    // Create parameter objects.
    AUParameter *param1 = [AUParameterTree createParameterWithIdentifier:@"param1" name:@"Parameter 1" address:myParam1 min:0 max:100 unit:kAudioUnitParameterUnit_Percent unitName:nil flags:0 valueStrings:nil dependentParameters:nil];

    // Initialize the parameter values.
    param1.value = 0.5;

    // Create the parameter tree.
    _parameterTree = [AUParameterTree createTreeWithChildren:@[ param1 ]];

    // Create the input and output busses (AUAudioUnitBus).
    // Create the input and output bus arrays (AUAudioUnitBusArray).

    // A function to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;

        switch (param.address) {
            case myParam1:
                return [NSString stringWithFormat:@"%.f", value];
            default:
                return @"?";
        }
    };

    self.maximumFramesToRender = 512;

    AVAudioFormat* audioFormat = AudioKit.format;
    NSError* error = nil;
    [AudioKit.engine enableManualRenderingMode:AVAudioEngineManualRenderingModeRealtime format:audioFormat maximumFrameCount:4096 error:&error];
    Conductor* conductor = [Conductor sharedInstance];
    [conductor start];
    _kernelPtr = (S1DSPKernel*)conductor.synth.internalAU->_kernelPtr; // I am a Mad God

    AUAudioUnitBus* inputBus = [[AUAudioUnitBus alloc] initWithFormat:audioFormat error:nil];
    AUAudioUnitBus* outputBus = [[AUAudioUnitBus alloc] initWithFormat:audioFormat error:nil];
    _inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeInput busses: @[inputBus]];
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses: @[outputBus]];

    return self;
}

#pragma mark - AUAudioUnit Overrides

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }

    // Validate that the bus formats are compatible.

    // Allocate your resources.
    _musicalContextBlock = self.musicalContextBlock;
    _outputEventBlock = self.MIDIOutputEventBlock;
    _transportStateBlock = self.transportStateBlock;

    return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    _musicalContextBlock = nil;
    _outputEventBlock = nil;
    _transportStateBlock = nil;
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    // Capture in locals to avoid Obj-C member lookups. If "self" is captured in render, we're doing it wrong. See sample code.

    __block AUHostMusicalContextBlock mcb = _musicalContextBlock;
    //__block AUMIDIOutputEventBlock moeb = _outputEventBlock;
    __block AUHostTransportStateBlock tcb = _transportStateBlock;
    __block S1DSPKernel* _kernelRef = _kernelPtr;

    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp *timestamp,
                              AVAudioFrameCount frameCount,
                              NSInteger outputBusNumber,
                              AudioBufferList *outputData,
                              const AURenderEvent *renderEventHead,
                              AURenderPullInputBlock pullInputBlock) {

        //
        if(mcb) {
            double currentTempo = 120.0;
            double timeSignatureNumerator = 0.0;
            NSInteger timeSignatureDenominator = 0;
            double currentBeatPosition = 0.0;
            NSInteger sampleOffsetToNextBeat = 0;
            double currentMeasureDownbeatPosition = 0.0;
            mcb(&currentTempo, &timeSignatureNumerator, &timeSignatureDenominator, &currentBeatPosition, &sampleOffsetToNextBeat, &currentMeasureDownbeatPosition );
            _kernelRef->setParameter(arpRate, currentTempo);
            //            NSLog("current tempo %f", self.currentTempo)
            //            NSLog("timeSignatureNumerator %f", timeSignatureNumerator)
            //            NSLog("timeSignatureDenominator %ld", timeSignatureDenominator)
        }

        if(tcb) {
            AUHostTransportStateFlags flags;
            double currentSamplePosition = 0.0;
            double cycleStartBeatPosition = 0.0;
            double cycleEndBeatPosition = 0.0;
            const BOOL result = tcb(&flags, &currentSamplePosition, &cycleStartBeatPosition, &cycleEndBeatPosition);
            if (!result) {
                NSLog(@"Cannot retrieve transport state from host");
            } else {
                if(flags & AUHostTransportStateChanged) {
                    //                NSLog("AUHostTransportStateChanged bit set")
                    //                NSLog("currentSamplePosition %f", currentSamplePosition)
                }

                if (flags & AUHostTransportStateMoving) {
                    //                NSLog("AUHostTransportStateMoving bit set");
                    //                NSLog("currentSamplePosition %f", currentSamplePosition)
                    //                NSLog("currentBeatPosition %f", currentBeatPosition);
                    //                NSLog("sampleOffsetToNextBeat %ld", sampleOffsetToNextBeat);
                    //                NSLog("currentMeasureDownbeatPosition %f", currentMeasureDownbeatPosition);
                }

                if(flags & AUHostTransportStateRecording) {
                    //                        NSLog("AUHostTransportStateRecording bit set")
                    //                        NSLog("currentSamplePosition %f", currentSamplePosition)
                }

                if(flags & AUHostTransportStateCycling) {
                    //                        NSLog("AUHostTransportStateCycling bit set")
                    //                        NSLog("currentSamplePosition %f", currentSamplePosition)
                    //                        NSLog("cycleStartBeatPosition %f", cycleStartBeatPosition)
                    //                        NSLog("cycleEndBeatPosition %f", cycleEndBeatPosition)
                }
            }
        }

        // Do event handling and signal processing here.
        AURenderEvent const* renderEvent = renderEventHead;
        while(renderEvent != nil) {
            switch(renderEvent->head.eventType) {
                case AURenderEventParameter:
                    break;
                case AURenderEventParameterRamp:
                    break;
                //TODO:CONDUCTOR
                case AURenderEventMIDI:
                {
                    AUMIDIEvent midiEvent = renderEvent->MIDI;
                    //AUEventSampleTime now = midiEvent.eventSampleTime - timestamp->mSampleTime;
                    uint8_t message = midiEvent.data[0] & 0xF0;
                    uint8_t channel = midiEvent.data[0] & 0x0F;
                    uint8_t data1 = midiEvent.data[1];
                    uint8_t data2 = midiEvent.data[2];
                    if (message == 0x80) {
                        // note off
                        NSLog(@"channel:%d, note off nn:%d", channel, data1);
                        _kernelRef->stopNote(data1);
                    } else if(message ==  0x90) {
                        if (data2 > 0) {
                            // note on
                            NSLog(@"channel:%d, note on nn:%d, vel:%d", channel, data1, data2);
                            _kernelRef->startNote(data1, data2);
                        } else {
                            // note off
                            NSLog(@"channel:%d, note off nn:%d", channel, data1);
                            _kernelRef->stopNote(data1);
                        }
                    } else if (message ==  0xA0) {
                        // poly key pressure
                        NSLog(@"channel:%d, poly key pressure nn:%d, p:%d", channel, data1, data2);
                        //Conductor.sharedInstance.polyKeyPressure(channel: channel, noteNumber: data1, pressure: data2)
                    } else if (message ==  0xB0) {
                        // controller change
                        //TODO:MARCUS: need to move mod wheel logic from vc to dsp (like pitchbend)
                        NSLog(@"channel:%d, controller change cc:%d, value:%d", channel, data1, data2);
                        //TODO:MARCUS: create dsp controller change method
                    } else if (message ==  0xC0) {
                        // program change
                        NSLog(@"channel:%d, program change preset #:%d", channel, data1);
                        //TODO:MARCUS: create dsp program change method
                    } else if (message ==  0xD0) {
                        // channel pressure
                        NSLog(@"channel:%d, channel pressure:%d", channel, data1);
                        //TODO:MARCUS: create dsp channelPressure method
                        //Conductor.sharedInstance.channelPressure(channel: channel, pressure: data1)
                    } else if (message ==  0xE0) {
                        // pitch bend
                        uint16_t pb = ((uint16_t)data2 << 7) + (uint16_t)data1;
                        NSLog(@"channel:%d, pitch bend fine:%d, course:%d, pb:%d", channel, data1, data2, pb);
                        _kernelRef->setParameter(pitchbend, pb);
                    }
#if 0
                    // perform midi output block on each event
                    if( moeb) {
                        // example from Gene's blog
                        // send back the original unchanged
                        moeb(now, 0, renderEvent->MIDI.length, renderEvent->MIDI.data);

                        // now make new MIDI data
                        // note on
                        uint8_t bytes[3];
                        bytes[0] = 0x90;
                        bytes[1] = data1;
                        bytes[2] = data2;
                        if (message == 0x90 && data2 != 0) {
                            bytes[1] = data1 + interval;
                            moeb(now, 0, 3, bytes);
                        }
                        // note off
                        bytes[0] = 0x90;
                        bytes[1] = data1;
                        bytes[2] = 0;
                        if (message == 0x90 && data2 == 0) {
                            bytes[1] = data1 + interval;
                            moeb(now, 0, 3, bytes);
                        }
                    }
#endif
                }
                    break;
                case AURenderEventMIDISysEx:
                    break;
                default:
                    break;
            }
            renderEvent = renderEvent->head.next;
        }

        AudioKit.engine.manualRenderingBlock(frameCount, outputData, nil);

        return noErr;
    };
}

@end

