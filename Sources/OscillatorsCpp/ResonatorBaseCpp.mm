/**
MIT License

Copyright (c) 2026 Alexandre R. J. Francois

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

#import "ResonatorBaseCpp.h"
#import "PhasorCppProtected.h"

#import <Foundation/Foundation.h>

#include "ResonatorBase.hpp"

using namespace oscillators_cpp;

@implementation ResonatorBaseCpp

- (instancetype)initWithFrequency:(float)frequency sampleRate:(float)sampleRate alpha:(float)alpha beta:(float)beta gamma:(float)gamma {
    if (self = [super init]) {
        self.oscillator = new ResonatorBase(frequency, sampleRate, alpha, beta, gamma);
    }
    return self;
}

- (ResonatorBase*)resonator {
    return (ResonatorBase*)self.oscillator;
}

- (float)power {
    return self.resonator->power();
}

- (float)amplitude {
    return self.resonator->amplitude();
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

- (float)beta {
    return self.resonator->beta();
}

- (void)setBeta:(float)beta {
    self.resonator->setBeta(beta);
}

- (float)omBeta {
    return self.resonator->omBeta();
}

- (float)gamma {
    return self.resonator->gamma();
}

- (void)setGamma:(float)gamma {
    self.resonator->setGamma(gamma);
}

- (float)omGamma {
    return self.resonator->omGamma();
}

- (float)instantaneousFrequency {
    return self.resonator->instantaneousFrequency();
}

- (float)c {
    return self.resonator->c();
}

- (float)s {
    return self.resonator->s();
}

- (float)cc {
    return self.resonator->cc();
}

- (float)ss {
    return self.resonator->ss();
}

- (float)phase {
    return self.resonator->phase();
}

- (float)dpc {
    return self.resonator->dpc();
}

- (float)dps {
    return self.resonator->dps();
}

- (float)deltaPhase {
    return self.resonator->deltaPhase();
}

- (void)updateWithSample:(float)sample {
    self.resonator->updateWithSample(sample);
}

@end
