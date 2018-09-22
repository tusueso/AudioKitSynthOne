//
//  WheelSettingsViewControllerswift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 12/26/17.
//  Copyright © 2017 AudioKit. All rights reserved.
//

import UIKit

protocol ModWheelDelegate: AnyObject {
    func didSelectRouting(newDestination: Int)
}

class WheelSettingsViewController: UIViewController {

    @IBOutlet weak var modWheelSegment: UISegmentedControl!
    weak var delegate: ModWheelDelegate?
    var modWheelDestination = 0
    @IBOutlet weak var pitchUpperRange: Stepper!
    @IBOutlet weak var pitchLowerRange: Stepper!

    override func viewDidLoad() {
        super.viewDidLoad()
        modWheelSegment.selectedSegmentIndex = modWheelDestination
        let c = Conductor.sharedInstance

        pitchUpperRange.maxValue = c.getMaximum(.pitchbendMaxSemitones)
        pitchUpperRange.minValue = c.getMinimum(.pitchbendMaxSemitones)
        pitchUpperRange.value = c.getSynthParameter(.pitchbendMaxSemitones)
        c.bind(pitchUpperRange, to: .pitchbendMaxSemitones)

        pitchLowerRange.maxValue = c.getMaximum(.pitchbendMinSemitones)
        pitchLowerRange.minValue = c.getMinimum(.pitchbendMinSemitones)
        pitchLowerRange.value = c.getSynthParameter(.pitchbendMinSemitones)
        c.bind(pitchLowerRange, to: .pitchbendMinSemitones)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pitchUpperRange.value = Conductor.sharedInstance.getSynthParameter(.pitchbendMaxSemitones)
        pitchLowerRange.value = Conductor.sharedInstance.getSynthParameter(.pitchbendMinSemitones)
    }

    @IBAction func routingValueDidChange(_ sender: UISegmentedControl) {
        delegate?.didSelectRouting(newDestination: sender.selectedSegmentIndex)
    }

    @IBAction func closeButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
