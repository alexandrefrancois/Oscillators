#import <Foundation/Foundation.h>
#import "OscillatorCpp.h"

@interface ResonatorCpp : OscillatorCpp
- (instancetype)initWithTargetFrequency:(float)frequency sampleDuration:(float)sampleDuration alpha:(float)alpha;
//- (float)frequency;
//- (float)sampleDuration;
- (float)alpha;
//- (float)amplitude;
//- (int)numSamplesInPeriod;
//- (void)copyWaveform:(float*)dest size:(int)size; // this is a bit ugly but avoids memory management issues
//- (float)waveformValue:(int)index;
- (void)copyAllPhases:(float*)dest size:(int)size; // this is a bit ugly but avoids memory management issues
- (float)allPhasesValue:(int)index;
- (void)updateAllPhases:(float)sample
NS_SWIFT_NAME(updateAllPhases(sample:));
- (void)update:(float)sample
NS_SWIFT_NAME(update(sample:));
- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride
NS_SWIFT_NAME(update(frame:frameLength:sampleStride:));

@end
