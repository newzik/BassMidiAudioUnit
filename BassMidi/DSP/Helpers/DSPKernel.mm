//
//  DSPKernel.mm
//  BassMidi
//
//  Created by Matthieu bouillaud on 17/03/2022.
//

#import "DSPKernel.hpp"

AURenderEvent DSPKernel::handleOneEvent(AURenderEvent const *event) {
    switch (event->head.eventType) {
        case AURenderEventParameter: {
            handleParameterEvent(event->parameter);
            break;
        }

        case AURenderEventMIDI: {
            auto newMidiEvent = handleMIDIEvent(event->MIDI);
            AURenderEvent newRenderEvent = *event;
            newRenderEvent.MIDI = newMidiEvent;
            return newRenderEvent;
        }
        default:
            break;
    }
    return *event;
}

void DSPKernel::performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const *&event, AUMIDIOutputEventBlock midiOut) {
    do {
        auto newEvent = handleOneEvent(event);

        if (newEvent.head.eventType == AURenderEventMIDI && midiOut)
        {
            midiOut(now, 0, newEvent.MIDI.length, newEvent.MIDI.data);
        }
        
        // Go to next event.
        event = event->head.next;

        // While event is not null and is simultaneous (or late).
    } while (event && event->head.eventSampleTime <= now);
}

/**
 This function handles the event list processing and rendering loop for you.
 Call it inside your internalRenderBlock.
 */
void DSPKernel::processWithEvents(AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount, AURenderEvent const *events, AUMIDIOutputEventBlock midiOut) {

    AUEventSampleTime now = AUEventSampleTime(timestamp->mSampleTime);
    AUAudioFrameCount framesRemaining = frameCount;
    AURenderEvent const *event = events;

    while (framesRemaining > 0) {
        // If there are no more events, we can process the entire remaining segment and exit.
        if (event == nullptr) {
            AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
            process(framesRemaining, bufferOffset);
            return;
        }

        // **** start late events late.
        auto timeZero = AUEventSampleTime(0);
        auto headEventTime = event->head.eventSampleTime;
        AUAudioFrameCount const framesThisSegment = AUAudioFrameCount(std::max(timeZero, headEventTime - now));

        // Compute everything before the next event.
        if (framesThisSegment > 0) {
            AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
            process(framesThisSegment, bufferOffset);

            // Advance frames.
            framesRemaining -= framesThisSegment;

            // Advance time.
            now += AUEventSampleTime(framesThisSegment);
        }
        performAllSimultaneousEvents(now, event, midiOut);
    }
}
