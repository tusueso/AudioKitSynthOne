//
//  SynthOneAUv3AudioUnit.m
//  SynthOneAUv3
//
//  Created by Aurelius Prochazka on 9/22/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#import "SynthOneAUv3AudioUnit.h"

#import <AVFoundation/AVFoundation.h>

// Define parameter addresses.
const AudioUnitParameterID myParam1 = 0;

@interface SynthOneAUv3AudioUnit ()

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

    return self;
}

#pragma mark - AUAudioUnit Overrides

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
#warning implementation must return non-nil AUAudioUnitBusArray
    return nil;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
#warning implementation must return non-nil AUAudioUnitBusArray
    return nil;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }

    // Validate that the bus formats are compatible.
    // Allocate your resources.
    if (self.musicalContextBlock) {
        _musicalContext = self.musicalContextBlock;

    } else {
        _musicalContext = nil;
    }

    if (self.MIDIOutputEventBlock) {
        _outputEventBlock = self.MIDIOutputEventBlock;

    } else {
        _outputEventBlock = nil;
    }

    if (self.musicalContextBlock) {
        _transportStateBlock = self.transportStateBlock;
    } else {
        _transportStateBlock = nil;
    }
    return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    // Deallocate your resources.
    [super deallocateRenderResources];
    _musicalContext = nil;
    _outputEventBlock = nil;
    _transportStateBlock = nil;
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    // Capture in locals to avoid Obj-C member lookups. If "self" is captured in render, we're doing it wrong. See sample code.

    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp *timestamp,
                              AVAudioFrameCount frameCount,
                              NSInteger outputBusNumber,
                              AudioBufferList *outputData,
                              const AURenderEvent *renderEventHead,
                              AURenderPullInputBlock pullInputBlock) {
        // Do event handling and signal processing here.
        AURenderEvent const* renderEvent = renderEventHead;
        while(renderEvent != nil) {
            switch(renderEvent->head.eventType) {
                case AURenderEventParameter:
                    break;
                case AURenderEventParameterRamp:
                    break;
                case AURenderEventMIDI:
                {
                    AUMIDIEvent midiEvent = renderEvent->MIDI;
                    uint8_t message = midiEvent.data[0] & 0xF0;
                    uint8_t channel = midiEvent.data[0] & 0x0F;
                    uint8_t data1 = midiEvent.data[1];
                    uint8_t data2 = midiEvent.data[2];
                    if (message == 0x80) {
                        // note off
                        //Conductor.sharedInstance.stop(channel: channel, noteNumber: data1)
                        NSLog(@"channel:%d, note off nn:%d", channel, data1);
                    } else if(message ==  0x90) {
                        if (data2 > 0) {
                            // note on
                            NSLog(@"channel:%d, note on nn:%d, vel:%d", channel, data1, data2);
                            //Conductor.sharedInstance.play(channel: channel, noteNumber: data1, velocity: data2)
                        } else {
                            // note off
                            NSLog(@"channel:%d, note off nn:%d", channel, data1);
                            //Conductor.sharedInstance.stop(channel: channel, noteNumber: data1)
                        }
                    } else if (message ==  0xA0) {
                        // poly key pressure
                        NSLog(@"channel:%d, poly key pressure nn:%d, p:%d", channel, data1, data2);
                        //Conductor.sharedInstance.polyKeyPressure(channel: channel, noteNumber: data1, pressure: data2)
                    } else if (message ==  0xB0) {
                        // controller change
                        NSLog(@"channel:%d, controller change cc:%d, value:%d", channel, data1, data2);
                        //Conductor.sharedInstance.controllerChange(channel: channel, cc: data1, value: data2)
                    } else if (message ==  0xC0) {
                        // program change
                        NSLog(@"channel:%d, program change preset #:%d", channel, data1);
                        //Conductor.sharedInstance.programChange(channel: channel, preset: data1)
                    } else if (message ==  0xD0) {
                        // channel pressure
                        NSLog(@"channel:%d, channel pressure:%d", channel, data1);
                        //Conductor.sharedInstance.channelPressure(channel: channel, pressure: data1)
                    } else if (message ==  0xE0) {
                        // pitch bend
                        uint16_t pb = ((uint16_t)data2 << 7) + (uint16_t)data1;
                        NSLog(@"channel:%d, pitch bend fine:%d, course:%d, pb:%d", channel, data1, data2, pb);
                        //Conductor.sharedInstance.pitchBend(channel: channel, amount: pb)
                    }
                }
                    break;
                case AURenderEventMIDISysEx:
                    break;
                default:
                    break;
            }
            renderEvent = renderEvent->head.next;
        }


        return noErr;
    };
}

@end

