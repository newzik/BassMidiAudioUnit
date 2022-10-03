//
//  BassMidiAudioUnit.m
//  BassMidi
//
//  Created by Matthieu bouillaud on 17/03/2022.
//

#import "BassMidiAudioUnit.h"
#include <stdint.h>
#include "bassmidi.h"

@interface BassMidiAudioUnit () {
    int32_t _instrument;
    int32_t _transposition;
    BOOL _isMuted;
}
@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;
@end


@implementation BassMidiAudioUnit
@synthesize parameterTree = _parameterTree;

#define kInvalidInstrumentCode -1

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) { return nil; }

    _kernelAdapter = [[BassMidiDSPKernelAdapter alloc] init];
    _instrument = kInvalidInstrumentCode;
    _transposition = 0;
    _isMuted = NO;
    [self setupAudioBuses];
    [self setupParameterTree];
    [self setupParameterCallbacks];
    return self;
}

#pragma mark - AUAudioUnit Setup

+ (BOOL)initBassMidi:(UInt32)sampleRate {
    return BASS_Init(0, sampleRate, 0, NULL, NULL);
}

- (BOOL)loadSoundFont:(NSString*)filePath {
    NSLog(@"loadSoundFont = %@", filePath);
    return [_kernelAdapter prepareWithSoundFont:filePath];
}

- (int32_t)instrument {
    return _instrument;
}

- (void)setInstrument:(int32_t)instrument {
    _instrument = instrument;
    [_kernelAdapter setInstrument: instrument];
}

- (int32_t)transposition {
    return _transposition;
}

- (void)setTransposition:(int32_t)transposition {
    _transposition = transposition;
    [_kernelAdapter setTransposition:transposition];
}

- (BOOL)isMuted {
    return _isMuted;
}

- (void)setIsMuted:(BOOL)isMuted {
    _isMuted = isMuted;
    [_kernelAdapter setIsMuted:isMuted];
}

- (void)setupAudioBuses {
    // Create the input and output bus arrays.
    _inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                             busType:AUAudioUnitBusTypeInput
                                                              busses: @[_kernelAdapter.inputBus]];
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                             busType:AUAudioUnitBusTypeOutput
                                                              busses: @[_kernelAdapter.outputBus]];
}

- (void)setupParameterTree {
    // Create parameter objects.
}

- (void)setupParameterCallbacks {
    // Make a local pointer to the kernel to avoid capturing self.
    __block BassMidiDSPKernelAdapter * kernelAdapter = _kernelAdapter;

    // implementorValueObserver is called when a parameter changes value.
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        [kernelAdapter setParameter:param value:value];
    };

    // implementorValueProvider is called when the value needs to be refreshed.
    _parameterTree.implementorValueProvider = ^(AUParameter *param) {
        return [kernelAdapter valueForParameter:param];
    };

    // A function to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;

        return [NSString stringWithFormat:@"%.f", value];
    };
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioFrameCount)maximumFramesToRender {
    return _kernelAdapter.maximumFramesToRender;
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    _kernelAdapter.maximumFramesToRender = maximumFramesToRender;
}

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (_kernelAdapter.outputBus.format.channelCount != _kernelAdapter.inputBus.format.channelCount) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
        }
        // Notify superclass that initialization was not successful
        self.renderResourcesAllocated = NO;

        return NO;
    }

    [super allocateRenderResourcesAndReturnError:outError];
    _kernelAdapter.musicalContextBlock = self.musicalContextBlock;
    _kernelAdapter.MIDIOutBlock = self.MIDIOutputEventBlock;
    if (_instrument != kInvalidInstrumentCode) {
        [_kernelAdapter setInstrument:_instrument];
    }
    [_kernelAdapter setTransposition:_transposition];
    [_kernelAdapter setIsMuted:_isMuted];
    [_kernelAdapter allocateRenderResources];
    return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    [_kernelAdapter deallocateRenderResources];

    // Deallocate your resources.
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    return _kernelAdapter.internalRenderBlock;
}

@end
