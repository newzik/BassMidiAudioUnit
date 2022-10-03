//
//  ViewController.swift
//  BassMidiAudioUnitHost
//
//  Created by Matthieu bouillaud on 17/03/2022.
//

import UIKit

class ViewController: UIViewController {

    let midiFileName = "Tutu - Miles Davis"

    lazy var sequencer: Sequencer = {
        let fileURL = Bundle.main.url(forResource: midiFileName, withExtension: "mid")!
        return Sequencer(fileUrl: fileURL)
    }()
   
    @IBOutlet var startStopButton: UIButton!
    @IBOutlet var transpositionLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    @IBOutlet var programChangeField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        startStopButton.setTitle("Start", for: .normal)
        startStopButton.setTitle("Stop", for: .selected)
        transpositionLabel.text = String(stepper.value)
        programChangeField.text = nil
        programChangeField.delegate = self

        sequencer.prepare { result in
            switch result {
            case .success:
                print("sequencer prepare SUCCESS")
            case .failure(let error):
                print("sequencer prepare Error = \(error)")
            }
        }
    }

    @IBAction func playIt(_ sender: Any) {
        playMidiFile()
    }
    
    @IBAction func transposition(_ button: UIStepper) {
        transpositionLabel.text = String(stepper.value)
        sequencer.transpose(Int(stepper.value))
    }

    @IBAction func mute(_ sender: UISwitch) {
        sequencer.muteAudioUnits(sender.isOn)
    }
    
    func playMidiFile() {
        if sequencer.isPlaying {
            sequencer.stop()
        } else {
            if sequencer.isPrepared {
                sequencer.play()
            }
        }
        startStopButton.isSelected = sequencer.isPlaying
    }

}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let programChange = programChangeField.text,
              let midiCode = Int32(programChange) else { return false }
        sequencer.forceProgramChange(midiCode)
        return true
    }

}

