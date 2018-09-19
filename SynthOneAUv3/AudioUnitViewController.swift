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
    
    @IBAction func start(_ sender: Any) {
        Conductor.sharedInstance.start()
    }
    override public func viewDidLayoutSubviews() {
        print("view did layout subview")
    }
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("new size \(size)")
    }

    @IBAction func preset1(_ sender: Any) {
        let d = [ "tuningMasterSet": [0.6,0.75,1.0,1.3333333333333333,1.6666666666666667],
                  "arpInterval": 8,
                  "resonance": 0.10000000149011612,
                  "pitchbendMinSemitones": -12,
                  "phaserMix": 1,
                  "uid": "77DA049C-6563-4C71-88DE-17B036D6648F",
                  "reverbHighPass": 455.3747863769531,
                  "lfo2Waveform": 0,
                  "cutoffLFO": 1,
                  "delayTime": 0.1666666716337204,
                  "decayLFO": 0,
                  "octavePosition": 0,
                  "reverbMix": 0.13500003516674042,
                  "subOsc24Toggled": 0,
                  "compressorMasterMakeupGain": 2,
                  "sustainLevel": 0.09749999642372134,
                  "bitcrushLFO": 0,
                  "delayMix": 0.15187497437000275,
                  "frequencyA4": 440,
                  "vco1Semitone": 0,
                  "vco1Volume": 0.800000011920929,
                  "userText": "AudioKit Synth One. Across the frozen tundra of the antarctic, there remains an icy cave where the sounds reveberate off the walls... Fecher",
                  "glide": 0,
                  "subVolume": 0,
                  "compressorReverbWetThreshold": -8,
                  "compressorReverbWetRatio": 13,
                  "fmLFO": 0,
                  "phaserNotchWidth": 800,
                  "name": "Frost Plucks",
                  "compressorReverbWetMakeupGain": 1.8799999952316284,
                  "waveform2": 0,
                  "lfoRate": 0.03125,
                  "vcoBalance": 0.5,
                  "reverbToggled": 1,
                  "tremoloLFO": 0,
                  "filterDecay": 0.09049999713897708,
                  "category": 2,
                  "widen": 1,
                  "compressorReverbInputRatio": 13,
                  "compressorReverbInputAttack": 0.0010000000474974509,
                  "compressorMasterThreshold": -9,
                  "compressorReverbWetRelease": 0.15000000596046448,
                  "lfo2Amplitude": 0.016666000708937638,
                  "delayInputResonance": 0,
                  "author": "",
                  "filterType": 0,
                  "arpRate": 60,
                  "arpDirection": 2,
                  "vco2Detuning": 0,
                  "seqOctBoost": [
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false
            ],
                  "midiBendRange": 2,
                  "isLegato": 0,
                  "arpIsSequencer": false,
                  "crushFreq": 48000,
                  "compressorMasterRatio": 20,
                  "cutoff": 7000,
                  "pitchLFO": 0,
                  "compressorReverbInputThreshold": -8.5,
                  "modWheelRouting": 0,
                  "isFavorite": false,
                  "noiseLFO": 0,
                  "decayDuration": 0.14209677278995514,
                  "isArpMode": 0,
                  "phaserRate": 12,
                  "waveform1": 0,
                  "vco2Volume": 0.800000011920929,
                  "subOscSquareToggled": 0,
                  "phaserFeedback": 0,
                  "compressorMasterAttack": 0.0010000000474974509,
                  "autoPanAmount": 0,
                  "position": 24,
                  "attackDuration": 0.0005000000237487259,
                  "compressorReverbInputMakeupGain": 1.8799999952316284,
                  "oscMixLFO": 0,
                  "filterAttack": 0.013000000268220901,
                  "arpTotalSteps": 8,
                  "reverbFeedback": 0.8625000715255737,
                  "vco2Semitone": 0,
                  "masterVolume": 0.6625000238418579,
                  "filterSustain": 0,
                  "filterRelease": 0.05649999901652336,
                  "arpOctave": 1,
                  "lfoAmplitude": 0,
                  "fmVolume": 1,
                  "isHoldMode": 0,
                  "detuneLFO": 0,
                  "delayToggled": 1,
                  "isMono": 0,
                  "compressorReverbInputRelease": 0.22499999403953552,
                  "lfoWaveform": 0,
                  "seqPatternNote": [
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0
            ],
                  "tempoSyncToArpRate": 1,
                  "filterEnvLFO": 0,
                  "delayFeedback": 0.6039999723434448,
                  "releaseDuration": 0.1186612918972969,
                  "seqNoteOn": [
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true
            ],
                  "compressorMasterRelease": 0.15000000596046448,
                  "filterADSRMix": 0.9399999976158142,
                  "delayInputCutoffTrackingRatio": 0.75,
                  "compressorReverbWetAttack": 0.0010000000474974509,
                  "autoPanFrequency": 0.25,
                  "isUser": true,
                  "tuningName": " 3 Harmonic+Subharmonic Series: Triad",
                  "bank": "BankA",
                  "pitchbendMaxSemitones": 12,
                  "fmAmount": 0,
                  "lfo2Rate": 0.03125,
                  "reverbMixLFO": 0,
                  "noiseVolume": 0,
                  "resonanceLFO": 0
            ] as [String : Any]

        let p = Preset(dictionary: d)
        self.loadPreset(p)
    }

    @IBAction func preset2(_ sender: Any) {
        let d = [
            "arpInterval": 12,
            "resonance": 0.10000000149011612,
            "pitchbendMinSemitones": -12,
            "phaserMix": 0.09250031411647797,
            "uid": "026B5600-A515-451C-8222-86A3279A4807",
            "reverbHighPass": 246.0500030517578,
            "lfo2Waveform": 0,
            "cutoffLFO": 1,
            "delayTime": 0.14999999105930328,
            "decayLFO": 2,
            "octavePosition": 0,
            "reverbMix": 0.1574999988079071,
            "subOsc24Toggled": 0,
            "compressorMasterMakeupGain": 2,
            "sustainLevel": 0.0700000450015068,
            "bitcrushLFO": 0,
            "delayMix": 0.1993750035762787,
            "frequencyA4": 440,
            "vco1Semitone": 0,
            "vco1Volume": 0.800000011920929,
            "userText": "AudioKit Synth One preset. Press and hold a key. Close your eyes. Take a journey to the past or future! \nCreated by Matthew Fecher",
            "glide": 0,
            "subVolume": 0.11750000715255737,
            "compressorReverbWetThreshold": -8,
            "compressorReverbWetRatio": 13,
            "fmLFO": 0,
            "phaserNotchWidth": 1000,
            "name": "Synthwave 1974",
            "compressorReverbWetMakeupGain": 1.8799999952316284,
            "waveform2": 0.9158878326416016,
            "lfoRate": 0.1388888955116272,
            "vcoBalance": 0.5199999809265137,
            "reverbToggled": 1,
            "tremoloLFO": 0,
            "filterDecay": 0.09999997913837436,
            "category": 1,
            "widen": 0,
            "compressorReverbInputRatio": 13,
            "compressorReverbInputAttack": 0.0010000000474974509,
            "compressorMasterThreshold": -9,
            "compressorReverbWetRelease": 0.15000000596046448,
            "lfo2Amplitude": 0.8525000214576721,
            "delayInputResonance": 0,
            "author": "",
            "filterType": 0,
            "arpRate": 100,
            "arpDirection": 0,
            "vco2Detuning": 1.6200004816055298,
            "seqOctBoost": [
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                true,
                false
            ],
            "midiBendRange": 2,
            "isLegato": 0,
            "arpIsSequencer": true,
            "crushFreq": 48000,
            "compressorMasterRatio": 20,
            "cutoff": 11145.7607421875,
            "pitchLFO": 0,
            "compressorReverbInputThreshold": -8.5,
            "modWheelRouting": 0,
            "isFavorite": false,
            "noiseLFO": 0,
            "decayDuration": 0.427499920129776,
            "isArpMode": 1,
            "phaserRate": 12,
            "waveform1": 0.3865979313850403,
            "vco2Volume": 0.800000011920929,
            "subOscSquareToggled": 0,
            "phaserFeedback": 0.39399996399879456,
            "compressorMasterAttack": 0.0010000000474974509,
            "autoPanAmount": 0.9125000238418579,
            "position": 0,
            "attackDuration": 0.0005000000237487259,
            "compressorReverbInputMakeupGain": 1.8799999952316284,
            "oscMixLFO": 0,
            "filterAttack": 0.0005000000237487259,
            "arpTotalSteps": 16,
            "reverbFeedback": 0.7253998517990112,
            "vco2Semitone": 0,
            "masterVolume": 1,
            "filterSustain": 0.03600001335144043,
            "filterRelease": 0.004999999888241291,
            "arpOctave": 0,
            "lfoAmplitude": 0.6674996018409729,
            "fmVolume": 1,
            "isHoldMode": 0,
            "detuneLFO": 0,
            "delayToggled": 1,
            "isMono": 1,
            "compressorReverbInputRelease": 0.22499999403953552,
            "lfoWaveform": 0,
            "seqPatternNote": [
                0,
                7,
                12,
                0,
                5,
                7,
                12,
                -2,
                0,
                7,
                12,
                -12,
                5,
                7,
                -12,
                -12
            ],
            "tempoSyncToArpRate": 1,
            "filterEnvLFO": 0,
            "delayFeedback": 0.13824951648712158,
            "releaseDuration": 0.2926129102706909,
            "seqNoteOn": [
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            ],
            "compressorMasterRelease": 0.15000000596046448,
            "filterADSRMix": 0.9990000128746033,
            "delayInputCutoffTrackingRatio": 0.75,
            "compressorReverbWetAttack": 0.0010000000474974509,
            "autoPanFrequency": 0.25,
            "isUser": true,
            "bank": "BankA",
            "pitchbendMaxSemitones": 12,
            "fmAmount": 0,
            "lfo2Rate": 0.1041666716337204,
            "reverbMixLFO": 0,
            "noiseVolume": 0,
            "resonanceLFO": 0
            ] as [String : Any]
        let p = Preset(dictionary: d)
        self.loadPreset(p)
    }


    private func loadPreset(_ activePreset: Preset) {
        print("loadPreset: \(activePreset.name)")
        guard let s = Conductor.sharedInstance.synth else {
            print("ERROR:can't load preset if synth is not initialized")
            return
        }

        s.setSynthParameter(.arpRate, activePreset.arpRate)
        s.setSynthParameter(.delayOn, activePreset.delayToggled)
        s.setSynthParameter(.delayFeedback, activePreset.delayFeedback)
        s.setSynthParameter(.delayMix, activePreset.delayMix)
        s.setSynthParameter(.delayTime, activePreset.delayTime)
        s.setSynthParameter(.delayInputCutoffTrackingRatio, activePreset.delayInputCutoffTrackingRatio)
        s.setSynthParameter(.delayInputResonance, activePreset.delayInputResonance)
        s.setSynthParameter(.reverbOn, activePreset.reverbToggled)
        s.setSynthParameter(.reverbFeedback, activePreset.reverbFeedback)
        s.setSynthParameter(.reverbHighPass, activePreset.reverbHighPass)
        s.setSynthParameter(.reverbMix, activePreset.reverbMix)
        s.setSynthParameter(.arpIsOn, activePreset.isArpMode)
        s.setSynthParameter(.arpIsSequencer, activePreset.arpIsSequencer ? 1 : 0 )
        for i in 0..<16 {
            s.setPattern(forIndex: i, activePreset.seqPatternNote[i])
            s.setOctaveBoost(forIndex: i, activePreset.seqOctBoost[i] ? 1 : 0)
            s.setNoteOn(forIndex: i, activePreset.seqNoteOn[i])
        }
        //            if let m = activePreset.tuningMasterSet {
        //                tuningsPanel.setTuning(name: activePreset.tuningName, masterArray: m)
        //            } else {
        //                tuningsPanel.setDefaultTuning()
        //            }

        s.setSynthParameter(.tempoSyncToArpRate, activePreset.tempoSyncToArpRate)
        s.setSynthParameter(.lfo1Rate, activePreset.lfoRate)
        s.setSynthParameter(.lfo2Rate, activePreset.lfo2Rate)
        s.setSynthParameter(.delayTime, activePreset.delayTime)
        s.setSynthParameter(.autoPanFrequency, activePreset.autoPanFrequency)
        s.setSynthParameter(.masterVolume, activePreset.masterVolume)
        s.setSynthParameter(.isMono, activePreset.isMono)
        s.setSynthParameter(.glide, activePreset.glide)
        s.setSynthParameter(.widen, activePreset.widen)
        s.setSynthParameter(.index1, activePreset.waveform1)
        s.setSynthParameter(.index2, activePreset.waveform2)
        s.setSynthParameter(.morph1SemitoneOffset, activePreset.vco1Semitone)
        s.setSynthParameter(.morph2SemitoneOffset, activePreset.vco2Semitone)
        s.setSynthParameter(.morph2Detuning, activePreset.vco2Detuning)
        s.setSynthParameter(.morph1Volume, activePreset.vco1Volume)
        s.setSynthParameter(.morph2Volume, activePreset.vco2Volume)
        s.setSynthParameter(.morphBalance, activePreset.vcoBalance)
        s.setSynthParameter(.subVolume, activePreset.subVolume)
        s.setSynthParameter(.subOctaveDown, activePreset.subOsc24Toggled)
        s.setSynthParameter(.subIsSquare, activePreset.subOscSquareToggled)
        s.setSynthParameter(.fmVolume, activePreset.fmVolume)
        s.setSynthParameter(.fmAmount, activePreset.fmAmount)
        s.setSynthParameter(.noiseVolume, activePreset.noiseVolume)
        s.setSynthParameter(.cutoff, activePreset.cutoff)
        s.setSynthParameter(.resonance, activePreset.resonance)
        s.setSynthParameter(.filterADSRMix, activePreset.filterADSRMix)
        s.setSynthParameter(.filterAttackDuration, activePreset.filterAttack)
        s.setSynthParameter(.filterDecayDuration, activePreset.filterDecay)
        s.setSynthParameter(.filterSustainLevel, activePreset.filterSustain)
        s.setSynthParameter(.filterReleaseDuration, activePreset.filterRelease)
        s.setSynthParameter(.attackDuration, activePreset.attackDuration)
        s.setSynthParameter(.decayDuration, activePreset.decayDuration)
        s.setSynthParameter(.sustainLevel, activePreset.sustainLevel)
        s.setSynthParameter(.releaseDuration, activePreset.releaseDuration)
        s.setSynthParameter(.bitCrushSampleRate, activePreset.crushFreq)
        s.setSynthParameter(.autoPanAmount, activePreset.autoPanAmount)
        s.setSynthParameter(.reverbOn, activePreset.reverbToggled)
        s.setSynthParameter(.reverbFeedback, activePreset.reverbFeedback)
        s.setSynthParameter(.reverbHighPass, activePreset.reverbHighPass)
        s.setSynthParameter(.reverbMix, activePreset.reverbMix)
        s.setSynthParameter(.delayOn, activePreset.delayToggled)
        s.setSynthParameter(.delayFeedback, activePreset.delayFeedback)
        s.setSynthParameter(.delayMix, activePreset.delayMix)
        s.setSynthParameter(.lfo1Index, activePreset.lfoWaveform)
        s.setSynthParameter(.lfo1Amplitude, activePreset.lfoAmplitude)
        s.setSynthParameter(.lfo2Index, activePreset.lfo2Waveform)
        s.setSynthParameter(.lfo2Amplitude, activePreset.lfo2Amplitude)
        s.setSynthParameter(.cutoffLFO, activePreset.cutoffLFO)
        s.setSynthParameter(.resonanceLFO, activePreset.resonanceLFO)
        s.setSynthParameter(.oscMixLFO, activePreset.oscMixLFO)
        s.setSynthParameter(.reverbMixLFO, activePreset.reverbMixLFO)
        s.setSynthParameter(.decayLFO, activePreset.decayLFO)
        s.setSynthParameter(.noiseLFO, activePreset.noiseLFO)
        s.setSynthParameter(.fmLFO, activePreset.fmLFO)
        s.setSynthParameter(.detuneLFO, activePreset.detuneLFO)
        s.setSynthParameter(.filterEnvLFO, activePreset.filterEnvLFO)
        s.setSynthParameter(.pitchLFO, activePreset.pitchLFO)
        s.setSynthParameter(.bitcrushLFO, activePreset.bitcrushLFO)
        s.setSynthParameter(.tremoloLFO, activePreset.tremoloLFO)
        s.setSynthParameter(.arpDirection, activePreset.arpDirection)
        s.setSynthParameter(.arpInterval, activePreset.arpInterval)
        s.setSynthParameter(.arpOctave, activePreset.arpOctave)
        s.setSynthParameter(.arpTotalSteps, activePreset.arpTotalSteps )
        s.setSynthParameter(.monoIsLegato, activePreset.isLegato )
        s.setSynthParameter(.phaserMix, activePreset.phaserMix)
        s.setSynthParameter(.phaserRate, activePreset.phaserRate)
        s.setSynthParameter(.phaserFeedback, activePreset.phaserFeedback)
        s.setSynthParameter(.phaserNotchWidth, activePreset.phaserNotchWidth)
        s.setSynthParameter(.filterType, activePreset.filterType)
        s.setSynthParameter(.compressorMasterRatio, activePreset.compressorMasterRatio)
        s.setSynthParameter(.compressorReverbInputRatio, activePreset.compressorReverbInputRatio)
        s.setSynthParameter(.compressorReverbWetRatio, activePreset.compressorReverbWetRatio)
        s.setSynthParameter(.compressorMasterThreshold, activePreset.compressorMasterThreshold)
        s.setSynthParameter(.compressorReverbInputThreshold, activePreset.compressorReverbInputThreshold)
        s.setSynthParameter(.compressorReverbWetThreshold, activePreset.compressorReverbWetThreshold)
        s.setSynthParameter(.compressorMasterAttack, activePreset.compressorMasterAttack)
        s.setSynthParameter(.compressorReverbInputAttack, activePreset.compressorReverbInputAttack)
        s.setSynthParameter(.compressorReverbWetAttack, activePreset.compressorReverbWetAttack)
        s.setSynthParameter(.compressorMasterRelease, activePreset.compressorMasterRelease)
        s.setSynthParameter(.compressorReverbInputRelease, activePreset.compressorReverbInputRelease)
        s.setSynthParameter(.compressorReverbWetRelease, activePreset.compressorReverbWetRelease)
        s.setSynthParameter(.compressorMasterMakeupGain, activePreset.compressorMasterMakeupGain)
        s.setSynthParameter(.compressorReverbInputMakeupGain, activePreset.compressorReverbInputMakeupGain)
        s.setSynthParameter(.compressorReverbWetMakeupGain, activePreset.compressorReverbWetMakeupGain)
        s.setSynthParameter(.delayInputCutoffTrackingRatio, activePreset.delayInputCutoffTrackingRatio)
        s.setSynthParameter(.delayInputResonance, activePreset.delayInputResonance)
        s.setSynthParameter(.pitchbendMinSemitones, activePreset.pitchbendMinSemitones)
        s.setSynthParameter(.pitchbendMaxSemitones, activePreset.pitchbendMaxSemitones)
        s.setSynthParameter(.frequencyA4, activePreset.frequencyA4)
        s.setSynthParameter(.oscBandlimitIndexOverride, activePreset.oscBandlimitIndexOverride)
        s.setSynthParameter(.oscBandlimitEnable, activePreset.oscBandlimitEnable)
        s.resetSequencer()
    }
}
