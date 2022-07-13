#import <Foundation/Foundation.h>

@interface OscillatorCpp : NSObject
- (instancetype)initWithTargetFrequency:(float)frequency sampleDuration:(float)sampleDuration;
- (float)frequency;
- (float)sampleDuration;
- (float)amplitude;
- (int)numSamplesInPeriod;
- (void)setSineWave;
- (void)copyWaveform:(float*)dest size:(int)size; // this is a bit ugly but avoids memory management issues
- (float)waveformValue:(int)index;
@end
