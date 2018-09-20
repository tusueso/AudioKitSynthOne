//
//  AudioUnitViewController.swift
//  SynthOneAUv3
//
//  Created by Aurelius Prochazka on 9/16/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import CoreAudioKit

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    
    public override func viewDidLoad() {
        print("view did load")
        super.viewDidLoad()
        
        if audioUnit == nil {
            print("returned with nil audiounit")
            return
        }
        
        // Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
        print("returned with non-nil audiounit")
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {

        print("creating audiounit")
        do {
            audioUnit = try SynthOneAUv3AudioUnit(componentDescription: componentDescription, options: [])

        } catch let err as NSError {
            print("erred with \(err)")
        }
        print("succesful!")
        return audioUnit!
    }

}
