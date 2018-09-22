//
//  Conductor.swift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 7/23/17.
//  Copyright © 2017 AudioKit. All rights reserved.
//

import AudioKit

protocol S1Control: class {
    var value: Double { get set }
    var callback: (Double) -> Void { get set }
}

typealias S1ControlCallback = (S1Parameter, S1Control?) -> ((_: Double) -> Void)

class Conductor: S1Protocol {
    static var sharedInstance = Conductor()
    var neverSleep = false {
        didSet {
            //LinkOpener.shared.isIdleTimerDisabled = neverSleep
        }
    }

    // Synth should not be directly accessible.
    // We need to build up a protocol for conductor/synth so aks1 can be a template project
    private var synth: AKSynthOne!
    private var started = false
    var tap: AKPolyphonicNode {
        get {
            return synth as AKPolyphonicNode
        }
    }

    var backgroundAudio = false
    var banks: [Bank] = []

    var bindings: [(S1Parameter, S1Control)] = []
    var heldNoteCount: Int = 0
    private var audioUnitPropertyListener: AudioUnitPropertyListener!
    let lfo1RateEffectsPanelID: Int32 = 1
    let lfo2RateEffectsPanelID: Int32 = 2
    let autoPanEffectsPanelID: Int32 = 3
    let delayTimeEffectsPanelID: Int32 = 4
    let lfo1RateTouchPadID: Int32 = 5
    let lfo1RateModWheelID: Int32 = 6
    let lfo2RateModWheelID: Int32 = 7
    let pitchBendID: Int32 = 8

    var iaaTimer: Timer = Timer()

    public var viewControllers: Set<UpdatableViewController> = []

    func bind(_ control: S1Control,
              to parameter: S1Parameter,
              callback closure: S1ControlCallback? = nil) {
        let binding = (parameter, control)
        bindings.append(binding)
        let control = binding.1
        if let cb = closure {
            // custom closure
            control.callback = cb(parameter, control)
        } else {
            // default closure
            control.callback = changeParameter(parameter, control)
        }
    }

    var changeParameter: S1ControlCallback  = { parameter, control in
        return { value in
            sharedInstance.synth.setSynthParameter(parameter, value)
            sharedInstance.updateSingleUI(parameter, control: control, value: value)
          }
        } {
        didSet {
            AKLog("WARNING: changeParameter callback changed")
        }
    }

    func updateSingleUI(_ parameter: S1Parameter,
                        control inputControl: S1Control?,
                        value inputValue: Double) {

        // cannot access synth until it is initialized and started
        if !started { return }

        // for every binding of type param
        for binding in bindings where parameter == binding.0 {
            let control = binding.1

            // don't update the control if it is the one performing the callback because it has already been updated
            if let inputControl = inputControl {
                if control !== inputControl {
                    control.value = inputValue
                }
            } else {
                // nil control = global update (i.e., preset change)
                control.value = inputValue
            }
        }

        // View controllers can own objects which are not updated by the bindings scheme.
        // For example, EnvelopesPanel has AKADSRView's which do not conform to S1Control
        for vc in viewControllers {
            vc.updateUI(parameter, control: inputControl, value: inputValue)
        }
    }

    // Call when a global update needs to happen.  i.e., on launch, foreground, and/or when a Preset is loaded.
    func updateAllUI() {
        let parameterCount = S1Parameter.S1ParameterCount.rawValue
        for address in 0..<parameterCount {
            guard let parameter: S1Parameter = S1Parameter(rawValue: address)
                else {
                    AKLog("ERROR: S1Parameter enum out of range: \(address)")
                    return
            }
            let value = synth.getSynthParameter(parameter)
            updateSingleUI(parameter, control: nil, value: value)
        }

        // Display Preset Name again
        guard let manager = self.viewControllers.first(
            where: { $0 is Manager }) as? Manager else { return }
        updateDisplayLabel("\(manager.activePreset.position): \(manager.activePreset.name)")
    }

    func start() {
        #if DEBUG
        AKSettings.enableLogging = true
        AKLog("Logging is ON")
        #else
        AKLog("Logging is OFF")
        #endif

        // Allow audio to play while the iOS device is muted.
        AKSettings.playbackWhileMuted = true

        do {
            try AKSettings.setSession(category: .playAndRecord,
                                      with: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
        } catch {
            AKLog("Could not set session category: \(error)")
        }

        // DEFAULT TUNING
        _ = AKPolyphonicNode.tuningTable.defaultTuning()

        synth = AKSynthOne()
        synth.delegate = self
        synth.rampDuration = 0.0 // Handle ramping internally instead of the ramper hack

        AudioKit.output = synth

        do {
            try AudioKit.start()
            #if DEBUG
            AKLog("AudioKit Started")
            #endif
        } catch {
            AKLog("AudioKit did not start! \(error)")
        }
        started = true

        #if AUV3_EXTENSION
        AKLog("Skipping Starting Audiobus")
        #else
        if let au = AudioKit.engine.outputNode.audioUnit {
            // IAA Host Icon
            audioUnitPropertyListener = AudioUnitPropertyListener { (_, _) in
                let headerVC = self.viewControllers.first(where: { $0 is HeaderViewController })
                    as? HeaderViewController

                headerVC?.hostAppIcon.image = AudioOutputUnitGetHostIcon(au, 44)
            }

            do {
                try au.add(listener: audioUnitPropertyListener,
                           toProperty: kAudioUnitProperty_IsInterAppConnected)
            } catch {
                AKLog("Unsuccessful")
            }
        }

        AKLog("Starting Audiobus")
        Audiobus.start()
        #endif
    }

    func updateDisplayLabel(_ message: String) {
        let manager = self.viewControllers.first(where: { $0 is Manager }) as? Manager
        manager?.updateDisplay(message)
    }

    func updateDisplayLabel(_ parameter: S1Parameter, value: Double) {
        let headerVC = self.viewControllers.first(where: { $0 is HeaderViewController }) as? HeaderViewController
        headerVC?.updateDisplayLabel(parameter, value: value)
    }

    // MARK: - boiler plate passthrough to AKSynthOne...make a conductor protocol and add these
    open func setSynthParameter(_ parameter: S1Parameter, _ value: Double) {
        guard started == true else {
            AKLog("race condition: Setting synth parameter \(parameter) before synth is started")
            return
        }
        synth.setSynthParameter(parameter, value)
    }

    open func getSynthParameter(_ parameter: S1Parameter) -> Double {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0
        }
        return synth.getSynthParameter(parameter)
    }

    open func getDependentParameter(_ parameter: S1Parameter) -> Double {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0
        }
        return synth.getDependentParameter(parameter)
    }

    open func setDependentParameter(_ parameter: S1Parameter, _ value: Double, _ payload: Int32) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.setDependentParameter(parameter, value, payload)
    }

    open func getMinimum(_ parameter: S1Parameter) -> Double {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0
        }
        return synth.getMinimum(parameter)
    }

    open func getMaximum(_ parameter: S1Parameter) -> Double {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0
        }
        return synth.getMaximum(parameter)
    }

    open func getRange(_ parameter: S1Parameter) -> ClosedRange<Double> {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0 ... 1
        }
        let min = synth.getMinimum(parameter)
        let max = synth.getMaximum(parameter)
        return min ... max
    }

    open func getDefault(_ parameter: S1Parameter) -> Double {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0
        }
        return synth.getDefault(parameter)
    }

    open func reset() {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.reset()
    }

    open func resetSequencer() {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.resetSequencer()
    }

    open func stopAllNotes() {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.stopAllNotes()
    }

    // AKPolyphonic

    // Function to play a NoteState with the note number with velocity.
    // DSP will choose frequency at note number (AKPolyphonicNode.tuningTable).
    open func play(channel: UInt8, noteNumber: MIDINoteNumber, velocity: MIDIVelocity) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.play(noteNumber: noteNumber, velocity: velocity)
    }

    // Function to play a NoteState with the note number with velocity at frequency
    open func play(channel: UInt8, noteNumber: MIDINoteNumber, velocity: MIDIVelocity, frequency: Double) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.play(noteNumber: noteNumber, velocity: velocity, frequency: frequency)
    }

    /// Function to stop the NoteNumber at note number
    open func stop(channel: UInt8, noteNumber: MIDINoteNumber) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.stop(noteNumber: noteNumber)
    }

    /// Sequncer function
    open func getPattern(forIndex inputIndex: Int) -> Int {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return 0
        }
        return synth.getPattern(forIndex: inputIndex)
    }

    /// Sequncer function
    open func setPattern(forIndex inputIndex: Int, _ value: Int) {
        synth.setPattern(forIndex: inputIndex, value)
    }

    /// Sequncer function
    open func getOctaveBoost(forIndex inputIndex: Int) -> Bool {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return false
        }
        return synth.getOctaveBoost(forIndex: inputIndex)
    }

    /// Sequncer function
    open func setOctaveBoost(forIndex inputIndex: Int, _ value: Double) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.setOctaveBoost(forIndex: inputIndex, value)
    }

    /// Sequncer function
    open func isNoteOn(forIndex inputIndex: Int) -> Bool {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return false
        }
        return synth.isNoteOn(forIndex: inputIndex)
    }

    /// Sequncer function
    open func setNoteOn(forIndex inputIndex: Int, _ value: Bool) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.setNoteOn(forIndex: inputIndex, value)
    }

    open func polyKeyPressure(channel: UInt8, noteNumber: UInt8, pressure: UInt8) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
    }

    open func controllerChange(channel: UInt8, cc: UInt8, value: UInt8) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }

        if cc == 1 {
            // Mod Wheel
            //TODO: ModWheel
//            let touchPadPanel = self.viewControllers.first(where: { $0 is TouchPadPanelController })
//                as? TouchPadPanelController
//            touchPadPanel?.dependentParameterDidChange(parameter)
        }
    }

    open func channelPressure(channel: UInt8, pressure: UInt8) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
    }

    open func programChange(channel: UInt8, preset: UInt8) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
    }

    open func pitchBend(channel: UInt8, amount: UInt16) {
        guard started == true else {
            AKLog("race condition: Accessing synth before it is started")
            return
        }
        synth.setSynthParameter(.pitchbend, Double(amount))
    }


    // MARK: - S1Protocol

    // called by DSP on main thread
    func dependentParameterDidChange(_ parameter: DependentParameter) {
        let effectsPanel = self.viewControllers.first(where: { $0 is EffectsPanelController })
            as? EffectsPanelController
        effectsPanel?.dependentParameterDidChange(parameter)

        let touchPadPanel = self.viewControllers.first(where: { $0 is TouchPadPanelController })
            as? TouchPadPanelController
        touchPadPanel?.dependentParameterDidChange(parameter)

        let manager = self.viewControllers.first(where: { $0 is Manager }) as? Manager
        manager?.dependentParameterDidChange(parameter)
    }

    // called by DSP on main thread
    func arpBeatCounterDidChange(_ beat: S1ArpBeatCounter) {
        let sequencerPanel = self.viewControllers.first(where: { $0 is SequencerPanelController })
            as? SequencerPanelController
        sequencerPanel?.updateLED(beatCounter: Int(beat.beatCounter), heldNotes: self.heldNoteCount)
    }

    // called by DSP on main thread
    func heldNotesDidChange(_ heldNotes: HeldNotes) {
        heldNoteCount = Int(heldNotes.heldNotesCount)
    }

    // called by DSP on main thread
    func playingNotesDidChange(_ playingNotes: PlayingNotes) {
        let tuningsPanel = self.viewControllers.first(where: { $0 is TuningsPanelController })
            as? TuningsPanelController
        tuningsPanel?.playingNotesDidChange(playingNotes)
    }

    // Start/Pause AK Engine (Conserve energy by turning background audio off)
    func startEngine(completionHandler: AKCallback? = nil) {
        AKLog("engine.isRunning: \(AudioKit.engine.isRunning)")
        if !AudioKit.engine.isRunning {
            do {
                try AudioKit.engine.start()
                AKLog("AudioKit: engine is started.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completionHandler?()
                }
            } catch {
                AKLog("Unable to start the audio engine. Probably fatal error")
            }

            return
        }
        completionHandler?()
    }

    func stopEngine() {
        AudioKit.engine.pause()
    }

    @objc func checkIAAConnectionsEnterBackground() {
        if let audiobusClient = Audiobus.client {
            if !audiobusClient.isConnected && !audiobusClient.isConnectedToInput && !backgroundAudio {
                deactivateSession()
                AKLog("disconnected without timer")
            } else {
                iaaTimer.invalidate()
                iaaTimer = Timer.scheduledTimer(timeInterval: 20 * 60,
                                                target: self,
                                                selector: #selector(self.checkIAAConnectionsEnterBackground),
                                                userInfo: nil, repeats: true)
            }
        }
    }

    func checkIAAConnectionsEnterForeground() {
        iaaTimer.invalidate()
        startEngine()
    }

    func deactivateSession() {
        stopEngine()
        do {
            try AKSettings.session.setActive(false)
        } catch let error as NSError {
            AKLog("error setting session: " + error.description)
        }
        iaaTimer.invalidate()
        AKLog("disconnected with timer")
    }

}
