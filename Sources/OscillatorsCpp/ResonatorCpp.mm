#import "ResonatorCpp.h"
#import "OscillatorCppProtected.h"

#import <Foundation/Foundation.h>

#include "Resonator.hpp"

using namespace oscillators_cpp;

@implementation ResonatorCpp

- (instancetype)initWithTargetFrequency:(float)frequency sampleDuration:(float)sampleDuration alpha:(float)alpha {
    if (self = [super init]) {
        self.oscillator = new Resonator(frequency, sampleDuration, alpha);
    }
    return self;
}

- (Resonator*)resonator {
    return (Resonator*)self.oscillator;
}

- (float)alpha {
    return self.resonator->alpha();
}

- (void)copyAllPhases:(float*)dest size: (int)size {
    self.resonator->copyAllPhases(dest, size);
}

- (float)allPhasesValue:(int)index {
    return self.resonator->allPhasesValue(index);
}

- (void)updateAllPhases:(float)sample {
    self.resonator->updateAllPhases(sample);
}

- (void)update:(float)sample {
    self.resonator->update(sample);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonator->update(frame, frameLength, sampleStride);
}

@end
