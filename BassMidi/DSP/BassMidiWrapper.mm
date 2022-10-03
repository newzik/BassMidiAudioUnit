//
//  BassMidiWrapper.mm
//  BassMidi
//
//  Created by Matthieu bouillaud on 04/04/2022.
//

#import "BassMidiWrapper.hpp"

bool BassMidiWrapper::prepare(const void *file) {
    // Disable automatic updating of playback buffers
    BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 0 );
    BASS_SetConfig(BASS_CONFIG_UPDATETHREADS, 0 );
    resetParameters();
    resetBassMIDI();
    if (createStream() == false) {
        return false;
    }
    if (loadSoundFont(file) == false) {
        return false;
    }
    return true;
}

DWORD BassMidiWrapper::getDecodedData(void *buffer, DWORD length) {
    // Retrieve Stereo (interleaved) data from BASS Midi output
    DWORD dataLength = BASS_ChannelGetData(_bassMidi.stream, buffer, length);
    if(dataLength == -1) {
        logBassError("BASS_ChannelGetData");
    }
    return dataLength;
}

void BassMidiWrapper::playEvent(uint32_t event, uint32_t note, uint32_t param) {
    BYTE events[3] = { (BYTE)event, (BYTE)note, (BYTE)param };
    DWORD result = BASS_MIDI_StreamEvents(_bassMidi.stream, BASS_MIDI_EVENTS_RAW, events, 3);
    if (result == -1) {
        logBassError("PLAY EVENT");
        return;
    }
}

void BassMidiWrapper::sendEvent(uint32_t event, uint32_t p1, uint32_t p2) {
    BYTE events[3] = { (BYTE)event, (BYTE)p1, (BYTE)p2 };
    if (BASS_MIDI_StreamEvents(_bassMidi.stream, BASS_MIDI_EVENTS_RAW, events, 3) == -1) {
        logBassError("SEND EVENT(3)");
    }
}

void BassMidiWrapper::sendEvent(uint32_t event, uint32_t p1) {
    BYTE events[2] = { (BYTE)event, (BYTE)p1 };
    if (BASS_MIDI_StreamEvents(_bassMidi.stream, BASS_MIDI_EVENTS_RAW, events, 2) == -1) {
        logBassError("SEND EVENT(2)");
    }
}

void BassMidiWrapper::setDrumsInstrument() {
    if (instrument == kDrumInstrument) {
        return;
    }
    instrument = kDrumInstrument;
    BASS_MIDI_StreamEvent(_bassMidi.stream, 0, MIDI_EVENT_DRUMS, 1);
}

void BassMidiWrapper::setInstrument(int32_t instrumentCode) {
    // PROGRAM from 0 to 127 (and Drums = 128)
    instrument = std::max(instrumentCode - 1, 0);
    if (instrument == kDrumInstrument) {
        setDrumsInstrument();
    } else {
        if(!BASS_MIDI_StreamEvent(_bassMidi.stream, 0, MIDI_EVENT_PROGRAM, instrument)) {
            logBassError("PROGRAM CHANGE");
        }
    }
}

void BassMidiWrapper::setTransposition(int32_t transposeValue) {
    // Don't apply transposition for Drums instrument
    if (instrument == kDrumInstrument) {
        return;
    }
    transpose = 100 + transposeValue;
    if(!BASS_MIDI_StreamEvent(_bassMidi.stream, 0, MIDI_EVENT_TRANSPOSE, transpose)) {
        logBassError("MIDI TRANSPOSE");
    }
}

