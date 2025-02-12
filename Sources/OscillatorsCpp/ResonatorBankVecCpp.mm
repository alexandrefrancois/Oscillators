/**
MIT License

Copyright (c) 2024-2025 Alexandre R. J. Francois

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

#import "ResonatorBankVecCpp.h"

#import <Foundation/Foundation.h>

#include "ResonatorBankVecCpp.hpp"

using namespace oscillators_cpp;

@interface ResonatorBankVecCpp()
@property oscillators_cpp::ResonatorBankVec *resonatorBank;
@end

@implementation ResonatorBankVecCpp

- (instancetype)initWithNumResonators:(int)numResonators frequencies:(const float*)frequencies alphas:(const float*)alphas betas:(const float*)betas sampleRate:(float)sampleRate {
    if (self = [super init]) {
        self.resonatorBank = new ResonatorBankVec(numResonators, frequencies, alphas, betas, sampleRate);
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

- (float)frequencyValue:(int)index {
    return self.resonatorBank->frequencyValue(index);
}

- (float)alphaValue:(int)index {
    return self.resonatorBank->alphaValue(index);
}

- (float)betaValue:(int)index {
    return self.resonatorBank->betaValue(index);
}

- (void)getPowers:(float*)dest size: (int)size {
    self.resonatorBank->getPowers(dest, size);
}

//- (float)powerValue:(int)index {
//    return self.resonatorBank->powerValue(index);
//}

- (void)getAmplitudes:(float*)dest size: (int)size {
    self.resonatorBank->getAmplitudes(dest, size);
}

//- (float)amplitudeValue:(int)index {
//    return self.resonatorBank->amplitudeValue(index);
//}

- (void)update:(float)sample {
    self.resonatorBank->update(sample);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonatorBank->update(frame, frameLength, sampleStride);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride powers:(float*)powers amplitudes:(float*)amplitudes {
    self.resonatorBank->update(frame, frameLength, sampleStride, powers, amplitudes);
}

@end
