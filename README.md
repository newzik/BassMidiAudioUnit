# BassMidiAudioUnit
[![GitHub license](https://img.shields.io/github/license/newzik/BassMidiAudioUnit)](https://github.com/newzik/BassMidiAudioUnit/blob/main/LICENSE)
![alt text](https://img.shields.io/badge/platform-iOS-blueviolet "platform: iOS")
![alt text](https://img.shields.io/badge/audiounit-AUv3-blue "audiounit: AUv3")

## Background
Apple's `AVAudioUnitSampler` doesn't support Soundfonts spec 2.01. This is a pity regarding the huge gain of quality brought by the support of "modulators" (more on this topic on sound designer Christian Collins' [blog](https://schristiancollins.wordpress.com/2016/03/02/using-soundfonts-in-2016/)).

That's why at [Newzik](https://www.newzik.com), we decided that instead we should use the great BASSMIDI player built by [Un4seen](https://www.un4seen.com/) which is one of the few library on the market to support SoundFont version 2.01.

## Overview
The goal of this project is to embed the BASSMIDI library into an AUv3 Audio Unit, so it acts as a Sampler node.
This way, it makes it possible to insert it into a graph of audio nodes handled by the iOS Audio Engine.

## Basic usage
The `BassMidiAudioUnit` is enclosed in a xcframework that you should import at the top of your file:
```swift
import BassMidiAudioUnitFramework
```

1. Set the sampling rate of the BASSMIDI library
```swift
BassMidiAudioUnit.setup(sampleRate: 44100)
```

2. Instantiate a BASSMIDI Audio Unit
```swift
BassMidiAudioUnit.instantiate(soundFontPath: soundFontPath) { result in
    guard case .success(let container) = result else { return }
}
```
This will return a container object of type :
```swift
public struct BassMidiAudioUnitContainer {
    public let avAudioUnit: AVAudioUnit
    public let audioUnit: BassMidiAudioUnit
}
```

This way you can attach and connect the `AVAudioUnit` object to the `AVAudioEngine` and set it as the `destinationAudioUnit` of a `AVMusicTrack`:

```swift
engine.attach(audioUnit)
let outputHWFormat = engine.outputNode.outputFormat(forBus: 0)
engine.connect(audioUnit, to: engine.mainMixerNode, format: outputHWFormat)
track.destinationAudioUnit = audioUnit
```

## Additional options
Several additional options can be performed on the audio unit including: transposition, mute and force a program change.

### Transposition
You can apply a MIDI transposition to the `BassMidiAudioUnit` object by setting a semitone offset value:
```swift
bassMidiAudioUnit.transposition = -2 // - 2 semitones
```

### Muting
It is also possible to mute the audio output of the `BassMidiAudioUnit`:
```swift
bassMidiAudioUnit.isMuted = true
```
### Force Program Change
We also can force a MIDI program change event, in order to select a specific MIDI instrument among the GM Program instrument sound list. 
(In this case, all subsequent Program Change Events contained in the MIDI sequence will be ignored)
```swift
bassMidiAudioUnit.instrument = 22 // Accordion
```
  
## About Newzik App 🎼
The [Newzik app](https://apps.apple.com/app/newzik-lecteur-de-partitions/id966963109) is a wonderful iOS app built for musicians, to create and organize your digital music library. Go check our [website](https://www.newzik.com) if you want to known more about us.

## License 
BassMidiAudioUnit is distributed under the MIT license. See [LICENSE](LICENSE) for details.
Please note that this license does not cover the BASS/BASSMIDI libraries, which need to be licensed separately.
