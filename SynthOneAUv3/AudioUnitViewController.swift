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
        } else {
            // per apple docs if au is loaded we need to connect ui to it
            // https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/AudioUnit.html
            print("viewDidLoad:AU is valid: connect ui")
            connectUIToAudioUnit()
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

        LinkOpener.shared.code = { url in
            print("Trying to open \(url)")
            if let context = self.extensionContext {
                context.open(url) { _ in
                    print("opened successfully supposedly")
                }
            } else {
                print("Extension Context is nil")
            }
        }

        if isViewLoaded {
            connectUIToAudioUnit()
        }
        
        return audioUnit!
    }

    // see apple doc ref in view did load
    public func connectUIToAudioUnit() {
        // Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the Audio Unit

        //TODO:ensure we only call this once
        //
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "LoadUI", sender: self)
        }
    }

}
