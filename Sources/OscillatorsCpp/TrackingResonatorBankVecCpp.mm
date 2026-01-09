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

#import "TrackingResonatorBankVecCpp.h"

#import <Foundation/Foundation.h>

#include "TrackingResonatorBankVec.hpp"

using namespace oscillators_cpp;

@interface TrackingResonatorBankVecCpp()
@property oscillators_cpp::TrackingResonatorBankVec *resonatorBank;
@end

@implementation TrackingResonatorBankVecCpp

- (instancetype)initWithNumResonators:(int)numResonators naturalFrequencies:(const float*)naturalFrequencies alphas:(const float*)alphas betas:(const float*)betas gammas:(const float*)gammas sampleRate:(float)sampleRate {
    if (self = [super init]) {
        self.resonatorBank = new TrackingResonatorBankVec(numResonators, naturalFrequencies, alphas, betas, gammas, sampleRate);
    }
    return self;
}

- (void)dealloc {
    delete self.resonatorBank;
}

- (float)sampleRate {
    return self.resonatorBank->sampleRate();
}

- (int)numResonators {
    return static_cast<int>(self.resonatorBank->numResonators());
}

- (void)getNaturalFrequencies:(float*)dest size: (int)size {
    self.resonatorBank->getNaturalFrequencies(dest, size);
}

- (void)getResonantFrequencies:(float*)dest size: (int)size {
    self.resonatorBank->getResonantFrequencies(dest, size);
}

- (void)getPowers:(float*)dest size: (int)size {
    self.resonatorBank->getPowers(dest, size);
}

- (void)getAmplitudes:(float*)dest size: (int)size {
    self.resonatorBank->getAmplitudes(dest, size);
}

- (void)getPhases:(float*)dest size: (int)size {
    self.resonatorBank->getPhases(dest, size);
}

- (void)getDeltaPhases:(float*)dest size: (int)size {
    self.resonatorBank->getDeltaPhases(dest, size);
}

- (float)accPower {
    return self.resonatorBank->accPower();
}

- (void)update:(float)sample {
    self.resonatorBank->update(sample);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonatorBank->update(frame, frameLength, sampleStride);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride powers:(float*)powers amplitudes:(float*)amplitudes {
    self.resonatorBank->update(frame, frameLength, sampleStride, powers, amplitudes);
}

- (void)setTimeConstant:(float)tau sampleRate:(float)sampleRate {
    self.resonatorBank->setTimeConstant(tau, sampleRate);
}

@end
