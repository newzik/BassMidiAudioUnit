import AVFoundation

public struct BassMidiAudioUnitContainer {
    public let avAudioUnit: AVAudioUnit
    public let audioUnit: BassMidiAudioUnit
}

extension BassMidiAudioUnit {

    enum BassMidiAudioUnitError: Error {
        case unknown
        case soundFontLoading
    }

    private static let subtype: FourCharCode = "bass"
    private static let manufacturer: FourCharCode = "nwzk"
    private static let componentName = "nwzk: BassMidi"
    private static let version: UInt32 = UInt32.max
    private static var registered = false

    private static let componentDescription: AudioComponentDescription = {
        // Ensure that AudioUnit type, subtype, and manufacturer match the extension's Info.plist values.
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_MusicDevice
        componentDescription.componentSubType = subtype
        componentDescription.componentManufacturer = manufacturer
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0
        return componentDescription
    }()

    private static func register() {
        guard !registered else { return }
        AUAudioUnit.registerSubclass(BassMidiAudioUnit.self,
                                     as: componentDescription,
                                     name: componentName,
                                     version: version)
        registered = true
    }

    public static func setup(sampleRate: UInt32) {
        initBassMidi(sampleRate)
    }
    
    public static func instantiate(soundFontPath: String, _ completion: @escaping (Result<BassMidiAudioUnitContainer, Error>) -> Void) {
        BassMidiAudioUnit.register()
        AVAudioUnit.instantiate(with: componentDescription, options: []) { unit, error in
            if let unit = unit, let bassMidiAudioUnit = unit.auAudioUnit as? BassMidiAudioUnit {
                let container = BassMidiAudioUnitContainer(avAudioUnit: unit, audioUnit: bassMidiAudioUnit)
                guard bassMidiAudioUnit.loadSoundFont(soundFontPath) else {
                    completion(.failure(BassMidiAudioUnitError.soundFontLoading))
                    return
                }
                completion(.success(container))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(BassMidiAudioUnitError.unknown))
            }
        }
    }
}

