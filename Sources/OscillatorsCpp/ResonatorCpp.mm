/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#import "ResonatorCpp.h"
#import "OscillatorCppProtected.h"

#import <Foundation/Foundation.h>

#include "Resonator.hpp"

using namespace oscillators_cpp;

@implementation ResonatorCpp

- (instancetype)initWithFrequency:(float)frequency sampleRate:(float)sampleRate alpha:(float)alpha {
    if (self = [super init]) {
        self.oscillator = new Resonator(frequency, sampleRate, alpha);
    }
    return self;
}

- (Resonator*)resonator {
    return (Resonator*)self.oscillator;
}

- (float)alpha {
    return self.resonator->alpha();
}

- (void)setAlpha:(float)alpha {
    self.resonator->setAlpha(alpha);
}

- (float)omAlpha {
    return self.resonator->omAlpha();
}

- (float)timeConstant {
    return self.resonator->timeConstant();
}

- (float)trackedFrequency {
    return self.resonator->trackedFrequency();
}

- (float)s {
    return self.resonator->s();
}

- (float)c {
    return self.resonator->c();
}

- (float)phase {
    return self.resonator->phase();
}

- (void)updateWithSample:(float)sample {
    self.resonator->updateWithSample(sample);
}

- (void)update:(float)sample {
    self.resonator->update(sample);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonator->update(frame, frameLength, sampleStride);
}

- (void)updateAndTrack:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonator->updateAndTrack(frame, frameLength, sampleStride);
}

@end
