//
//  BassMidiWrapper.hpp
//  BassMidi
//
//  Created by Matthieu bouillaud on 04/04/2022.
//

#ifndef BassMidiWrapper_hpp
#define BassMidiWrapper_hpp

#include <stdio.h>
#include "bassmidi.h"
#include <string>

#define STRING(num) #num

typedef struct BassMidi {
    HSOUNDFONT soundfont;
    HSTREAM stream;
    HSYNC sync;
    HDSP dsp;
} BassMidi;

// Put your DSP code into a subclass of DSPKernel.
class BassMidiWrapper {
public:

    bool prepare(const void *file);
    
    DWORD getDecodedData(void *buffer, DWORD length);
    
    void playEvent(uint32_t event, uint32_t note, uint32_t param);

    void sendEvent(uint32_t event, uint32_t p1, uint32_t p2);

    void sendEvent(uint32_t event, uint32_t p1);

    void setDrumsInstrument();

    void setInstrument(int32_t instrumentCode);
    
    void setTransposition(int32_t transposeValue);

private:
    BassMidi _bassMidi;
    int32_t transpose;
    int16_t instrument;

#pragma mark - Consts
    const BYTE    kDrumInstrument = 0x80;
    const int32_t kSoundVolume = 100;
  
#pragma mark - Private methods

    static void logBassError(const char *message) {
        printf("ERROR BASS MIDI: %s = %d\n", message, BASS_ErrorGetCode());
    }

    bool createStream() {
        errno = 0;
        _bassMidi.stream = BASS_MIDI_StreamCreate(1, BASS_SAMPLE_FLOAT | BASS_STREAM_DECODE, 1);
        if(BASS_ErrorGetCode() != 0) {
            logBassError("STREAM CREATE");
            return false;
        }
        return true;
    }

    bool loadSoundFont(const void *file) {
        // Load soundfount and store it
        errno = 0;
        
        HSOUNDFONT newfont = BASS_MIDI_FontInit(file, 0);
        
        if(newfont) {
            BASS_MIDI_FONT soundfont;
            soundfont.font = newfont;
            soundfont.preset = -1;
            soundfont.bank = 0;
            if(!BASS_MIDI_StreamSetFonts(_bassMidi.stream, &soundfont, 1)) {
                logBassError("SET FONT");
                return false;
            }
            _bassMidi.soundfont = newfont;
            return true;
        }
        logBassError("FONT INIT");
        return false;
    }

    void playTestEvent() {
        if (BASS_MIDI_StreamEvent(_bassMidi.stream, 0, MIDI_EVENT_NOTE, MAKEWORD(4 * 12, 128)) == false) {
            logBassError("PLAY TEST EVENT");
            return;
        }
        printVoicesActive();
    }

    void printVoicesActive() {
        float activeVoices = -1;
        if (BASS_ChannelGetAttribute(_bassMidi.stream, BASS_ATTRIB_MIDI_VOICES_ACTIVE, &activeVoices) == false) {
            logBassError("GET VOICES_ACTIVE");
            return;
        }
        printf("BASS_ATTRIB_MIDI_VOICES_ACTIVE = %f\n", activeVoices);
    }

    void getConfig() {
        DWORD config = BASS_GetConfig(BASS_CONFIG_MIDI_SAMPLEMEM);
        printf("BASS_CONFIG_MIDI_SAMPLEMEM = %d\n", config);
    }
    
    void resetParameters() {
        transpose = 0;
        instrument = 0x0;
    }

    void resetBassMIDI() {
        _bassMidi.dsp = 0;
        _bassMidi.sync = 0;
        _bassMidi.soundfont = 0;
        _bassMidi.stream = 0;
    }

};

#endif /* BassMidiWrapper_hpp */
