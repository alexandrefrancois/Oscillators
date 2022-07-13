#import <Foundation/Foundation.h>

#import "OscillatorCpp.h"
#import "OscillatorCppProtected.h"

using namespace oscillators_cpp;

@implementation OscillatorCpp

- (instancetype)initWithTargetFrequency:(float)frequency sampleDuration:(float)sampleDuration {
    if (self = [super init]) {
        self.oscillator = new Oscillator(frequency, sampleDuration);
    }
    return self;
}

- (float)frequency {
    return self.oscillator->frequency();
}

- (float)sampleDuration {
    return self.oscillator->sampleDuration();
}

- (float)amplitude {
    return self.oscillator->amplitude();
}

- (int)numSamplesInPeriod {
    return self.oscillator->numSamplesInPeriod();
}

- (void)setSineWave {
    self.oscillator->setSineWave();
}

- (void)copyWaveform:(float*)dest size: (int)size {
    self.oscillator->copyWaveform(dest, size);
}

- (float)waveformValue:(int)index {
    return self.oscillator->waveformValue(index);
}

@end
