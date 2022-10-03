//
//  BassMidiDSPKernel.hpp
//  BassMidi
//
//  Created by Matthieu bouillaud on 15/02/2022.
//

#ifndef BassMidiDSPKernel_hpp
#define BassMidiDSPKernel_hpp

#import "DSPKernel.hpp"
#include "bassmidi.h"
#include <string>
#include <stdio.h>
#include "BassMidiWrapper.hpp"

#define STRING(num) #num
#define kDrumsMidiChannel 9

// Midi Channel Events type
NS_ENUM(UInt8, NZMIDIChannelEvent) {
    /// Stop playing the note
    kMidiChannelEventNoteOff        = 0x80,
    /// Start playing the note
    kMidiChannelEventNoteOn            = 0x90,
    /// Polyphonic Key Pressure (Aftertouch)
    kMidiChannelEventAfterTouch        = 0xA0,
    /// Control Change
    kMidiChannelEventControlChange    = 0xB0,
    /// Program Change
    kMidiChannelEventProgramChange    = 0xC0,
    /// Channel Pressure (After-touch)
    kMidiChannelEventChannelPressure    = 0xD0,
    /// Pitch Bend Change
    kMidiChannelEventPitchBend        = 0xE0,
};

/*
 BassMidiDSPKernel
 Performs simple copying of the input signal to the output.
 As a non-ObjC class, this is safe to use from render thread.
 */
class BassMidiDSPKernel : public DSPKernel {
public:

    // MARK: Member Functions

    BassMidiDSPKernel() {}

    void init(int channelCount, double inSampleRate) {
        chanCount = channelCount;
        sampleRate = float(inSampleRate);
    }

    void reset() {
    }

    bool isBypassed() {
        return bypassed;
    }

    void setBypass(bool shouldBypass) {
        bypassed = shouldBypass;
    }

    void setParameter(AUParameterAddress address, AUValue value) {
    }

    AUValue getParameter(AUParameterAddress address) {
        return 0.f;
    }

    void setBuffers(AudioBufferList* inBufferList, AudioBufferList* outBufferList) {
        inBufferListPtr = inBufferList;
        outBufferListPtr = outBufferList;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {

        // Retrieve Stereo (interleaved) data from BASS Midi output
        float* data = new float[frameCount * chanCount];
        DWORD length = bassMidi.getDecodedData(data, frameCount * sizeof(float) * chanCount);

        if (bypassed || _isMuted) {
            // Pass the samples through
            for (int channel = 0; channel < chanCount; ++channel) {
                if (inBufferListPtr->mBuffers[channel].mData ==  outBufferListPtr->mBuffers[channel].mData) {
                    continue;
                }
                
                for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
                    const int frameOffset = int(frameIndex + bufferOffset);
                    const float* in  = (float*)inBufferListPtr->mBuffers[channel].mData + frameOffset;
                    float* out = (float*)outBufferListPtr->mBuffers[channel].mData + frameOffset;
                    *out = *in;
                }
            }
            return;
        }

        // Copy decoded data to output buffer
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            const int frameOffset = int(frameIndex + bufferOffset);
            for (int channel = 0; channel < chanCount; ++channel) {
                float* out = (float*)outBufferListPtr->mBuffers[channel].mData;
                // Copy BassMidi output sample data to the audio unit's output buffer
                out[frameOffset] = length == -1 ? 0 : data[frameIndex * 2 + channel];
            }
        }
    }

    void handleContext(AUHostMusicalContextBlock block) {
        musicalContextBlock = block;
    }

    // Process midi events here and send them to the BassMIDI instance
    AUMIDIEvent handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
        AUMIDIEvent event = midiEvent;
        uint8_t status = event.data[0] & 0xf0;
        uint8_t channel = event.data[0] & 0x0f;
        // If the event is on the Drums channel then force the drums program change
        if (channel == kDrumsMidiChannel) {
            bassMidi.setDrumsInstrument();
        }
        switch (status) {
            case kMidiChannelEventNoteOn:
            case kMidiChannelEventNoteOff:
            case kMidiChannelEventAfterTouch: {
                uint32_t bassMidiEvent = status;
                uint32_t note = event.data[1];
                uint32_t param = event.data[2];
                if (note < 128) {
                    bassMidi.playEvent(bassMidiEvent, note, param);
                }
                break;
            }
            case kMidiChannelEventControlChange:
            case kMidiChannelEventPitchBend: {
                uint32_t bassMidiEvent = status;
                uint32_t note = event.data[1];
                uint32_t param = event.data[2];
                bassMidi.playEvent(bassMidiEvent, note, param);
                break;
            }
            case kMidiChannelEventProgramChange: {
                // Process Program Change Events only if instrument hasn't been overridden
                if (_overrideInstrument == -1) {
                    uint32_t bassMidiEvent = status;
                    uint32_t p1 = event.data[1];
                    bassMidi.sendEvent(bassMidiEvent, p1);
                }
                break;
            }
            case kMidiChannelEventChannelPressure: {
                uint32_t bassMidiEvent = status;
                uint32_t p1 = event.data[1];
                bassMidi.sendEvent(bassMidiEvent, p1);
                break;
            }
        }
        return event;
    }

    bool prepare(std::string fontPath) {
        return bassMidi.prepare(fontPath.c_str());
    }
    
    // MARK: Params accessors

    void setInstrument(int32_t instrument) {
        _overrideInstrument = instrument;
        bassMidi.setInstrument(_overrideInstrument);
    }
    
    int32_t getInstrument() {
        return _overrideInstrument;
    }

    void setTransposition(int32_t transposition) {
        _transposition = transposition;
        bassMidi.setTransposition(transposition);
    }
    
    int32_t getTransposition() {
        return _transposition;
    }

    void setIsMuted(bool isMuted) {
        _isMuted = isMuted;
    }

    BOOL getIsMuted() {
        return _isMuted;
    }
    
    // MARK: Member Variables

private:
    int32_t _overrideInstrument = -1;
    int32_t _transposition = 0;
    bool _isMuted = false;

    int chanCount = 0;
    float sampleRate = 44100.0;
    bool bypassed = false;
    AudioBufferList* inBufferListPtr = nullptr;
    AudioBufferList* outBufferListPtr = nullptr;

    AUHostMusicalContextBlock musicalContextBlock;

    // Bass MIDI instance
    BassMidiWrapper bassMidi;
     
#pragma mark - Private methods

};

#endif /* BassMidiDSPKernel_hpp */
