/**
MIT License

Copyright (c) 2025-2026 Alexandre R. J. Francois

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

#import "TrackingResonatorCpp.h"
#import "PhasorCppProtected.h"

#import <Foundation/Foundation.h>
#import "TrackingResonatorCpp.h"

#include "TrackingResonator.hpp"
#include "TrackingRuleBridge.hpp"

using namespace oscillators_cpp;

@implementation TrackingResonatorCpp

- (instancetype)initWithNaturalFrequency:(float)naturalFrequency alpha:(float)alpha beta:(float)beta gamma:(float)gamma trackingRule:(TrackingRuleCpp)trackingRule sampleRate:(float)sampleRate {
    if (self = [super init]) {
        self.oscillator = new TrackingResonator(naturalFrequency, alpha, beta, gamma, toTrackingRule(trackingRule), sampleRate);
    }
    return self;
}

- (TrackingResonator*)resonator {
    return (TrackingResonator*)self.oscillator;
}

- (float)naturalFrequency {
    return self.resonator->naturalFrequency();
}

- (void)setNaturalFrequency:(float)frequency alpha:(float)alpha beta:(float)beta gamma:(float)gamma {
    return self.resonator->setNaturalFrequency(frequency, alpha, beta, gamma);
}

- (float)resonantFrequency {
    return self.resonator->resonantFrequency();
}

- (void)update:(float)sample maxPower:(float)maxPower {
    self.resonator->update(sample, maxPower);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride maxPower:(float)maxPower {
    self.resonator->update(frame, frameLength, sampleStride, maxPower);
}

@end
