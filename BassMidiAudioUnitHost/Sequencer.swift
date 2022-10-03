//
//  Sequencer.swift
//  BassMidiAudioUnitHost
//
//  Created by Matthieu bouillaud on 04/02/2022.
//

import Foundation
import AVFoundation
import BassMidiAudioUnitFramework

class Sequencer {
    private var engine = AVAudioEngine()
    private var bassMidiUnits = [BassMidiAudioUnit]()
    private let soundFontName = "Soundfont - FluidR3 GM (20011225)"
    private lazy var sequencer = AVAudioSequencer(audioEngine: engine)

    private let fileUrl: URL
    public private(set) var isPrepared: Bool = false

    init(fileUrl: URL) {
        self.fileUrl = fileUrl
    }
    
    public func prepare(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try setupAudioSession()
            try sequencer.load(from: fileUrl)
        } catch {
            completion(.failure(error))
        }

        guard let soundFontPath = Bundle.main.path(forResource: soundFontName, ofType: "sf2") else {
            fatalError("Could not find soundFont with name: \(soundFontName)")
        }

        // Setup the sampling rate for the BassMidi library according to the engine's'
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        BassMidiAudioUnit.setup(sampleRate: UInt32(sampleRate))
        
        // Instantiate a Bass Midi audio unit for each track
        let group = DispatchGroup()
        for track in self.sequencer.tracks {
            group.enter()
            BassMidiAudioUnit.instantiate(soundFontPath: soundFontPath) { [weak self] result in
                guard let self = self,
                    case .success(let container) = result else { return }
                self.connect(track: track, to: container.avAudioUnit)
                self.bassMidiUnits.append(container.audioUnit)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isPrepared = true
            completion(.success(()))
        }
    }

    public func forceProgramChange(_ midiCode: Int32) {
        bassMidiUnits.forEach({ $0.instrument = midiCode })
    }

    public func toggleInstrument(_ instrA: Bool) {
        bassMidiUnits.forEach({ $0.instrument = instrA ? 129 : 128 })
    }
    
    public func transpose(_ value: Int) {
        bassMidiUnits.forEach({ $0.transposition = Int32(value) })
    }

    public func muteAudioUnits(_ mute: Bool) {
        bassMidiUnits.forEach({ $0.isMuted = mute })
    }

    public func play() {
        if sequencer.isPlaying {
            sequencer.stop()
        }
        if !engine.isRunning {
            startEngine()
        }
        sequencer.currentPositionInBeats = 0
        sequencer.prepareToPlay()
        do {
            try sequencer.start()
        } catch {
            print("Cannot start sequencer: \(error)")
        }
    }

    public func stop() {
        if sequencer.isPlaying {
            sequencer.stop()
        }
    }

    public var isPlaying: Bool {
        return sequencer.isPlaying
    }
}

// MARK: - Private methods
private extension Sequencer {

    func connect(track: AVMusicTrack, to audioUnit: AVAudioUnit) {
        engine.attach(audioUnit)
        let outputHWFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(audioUnit, to: engine.mainMixerNode, format: outputHWFormat)
        track.destinationAudioUnit = audioUnit
    }

    func startEngine() {
        do {
            try engine.start()
        } catch {
            print("Couldn't start engine: \(error)")
        }
    }

    func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(AVAudioSession.Category.playback)
        } catch {
            print("Could not set session category: \(error)")
            throw error
        }
        do {
            try session.setActive(true)
        } catch {
            print("Could not make session active: \(error)")
            throw error
        }
    }
}
