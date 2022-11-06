/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

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

#import "ResonatorBankCpp.h"

#import <Foundation/Foundation.h>

#include "ResonatorBank.hpp"

using namespace oscillators_cpp;

@interface ResonatorBankCpp()
@property oscillators_cpp::ResonatorBank *resonatorBank;
@end

@implementation ResonatorBankCpp

- (instancetype)initWithNumResonators:(int)numResonators targetFrequencies:(float*)targetFrequencies sampleDuration:(float)sampleDuration alphas:(float*)alphas {
    if (self = [super init]) {
        self.resonatorBank = new ResonatorBank(numResonators, targetFrequencies, sampleDuration, alphas);
    }
    return self;
}

- (void)dealloc {
    delete self.resonatorBank;
}

- (float)sampleDuration {
    return self.resonatorBank->sampleDuration();
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

- (void)setAllAlphas:(float)alpha {
    self.resonatorBank->setAllAlphas(alpha);
}

- (float)timeConstantValue:(int)index {
    return self.resonatorBank->timeConstantValue(index);
}

- (void)copyAmplitudes:(float*)dest size: (int)size {
    self.resonatorBank->copyAmplitudes(dest, size);
}

- (float)amplitudeValue:(int)index {
    return self.resonatorBank->amplitudeValue(index);
}

- (void)update:(float)sample {
    self.resonatorBank->update(sample);
}

- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonatorBank->update(frame, frameLength, sampleStride);
}

- (void)updateGF:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonatorBank->updateGF(frame, frameLength, sampleStride);
}

- (void)updateSeq:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride {
    self.resonatorBank->updateSeq(frame, frameLength, sampleStride);
}

@end
