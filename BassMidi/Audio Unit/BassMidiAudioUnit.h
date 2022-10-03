//
//  BassMidiAudioUnit.h
//  BassMidi
//
//  Created by Matthieu bouillaud on 17/03/2022.
//

#import <AudioToolbox/AudioToolbox.h>
#import <BassMidiAudioUnitFramework/BassMidiDSPKernelAdapter.h>
#import <AVFoundation/AVFoundation.h>

@interface BassMidiAudioUnit : AUAudioUnit

@property (nonatomic, readonly) BassMidiDSPKernelAdapter *kernelAdapter;
- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
+ (BOOL)initBassMidi:(UInt32)sampleRate;
- (BOOL)loadSoundFont:(NSString*)path;

@property (nonatomic) int32_t instrument;
@property (nonatomic) int32_t transposition;
@property (nonatomic) BOOL isMuted;

@end
