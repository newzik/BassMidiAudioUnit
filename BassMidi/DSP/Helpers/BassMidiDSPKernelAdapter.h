//
//  BassMidiDSPKernelAdapter.h
//  BassMidi
//
//  Created by Matthieu bouillaud on 15/02/2022.
//

#import <AudioToolbox/AudioToolbox.h>

@class AudioUnitViewController;

NS_ASSUME_NONNULL_BEGIN

@interface BassMidiDSPKernelAdapter : NSObject

@property (nonatomic) AUAudioFrameCount maximumFramesToRender;
@property (nonatomic, readonly) AUAudioUnitBus *inputBus;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;
- (AUValue)valueForParameter:(AUParameter *)parameter;

- (void)allocateRenderResources;
- (void)deallocateRenderResources;
- (AUInternalRenderBlock)internalRenderBlock;
- (void)setMusicalContextBlock:(AUHostMusicalContextBlock)musicalContextBlock;
- (void)setMIDIOutBlock:(AUMIDIOutputEventBlock)midiOutputEventBlock;

//
- (BOOL)prepareWithSoundFont:(NSString *)fontPath;

- (int32_t)getInstrument;
- (void)setInstrument:(int32_t)instrument;

- (int32_t)getTransposition;
- (void)setTransposition:(int32_t)transposition;

- (BOOL)getIsMuted;
- (void)setIsMuted:(BOOL)isMuted;

@end

NS_ASSUME_NONNULL_END
