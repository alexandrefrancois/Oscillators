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

#import <Foundation/Foundation.h>

#import "TrackingRuleCpp.h"

// Wrapper for the TrackingResonatorBank class
@interface TrackingResonatorBankCpp : NSObject
- (instancetype)initWithNumResonators:(int)numResonators naturalFrequencies:(const float*)frequencies sampleRate:(float)sampleRate alphas:(const float*)alphas betas:(const float*)betas gammas:(const float*)gammas trackingRule:(TrackingRuleCpp)trackingRule thresholdDB:(float)thresholdDB;
- (float)sampleRate;
- (int)numResonators;
- (void)getAlphas:(float*)dest size:(int)size;
- (void)getNaturalFrequencies:(float*)dest size:(int)size;
- (void)getOmegas:(float*)dest size:(int)size;
- (void)getResonantFrequencies:(float*)dest size:(int)size;
- (float)resonantFrequencyValue:(int)index;
- (void)getPowers:(float*)dest size:(int)size;
- (void)getAmplitudes:(float*)dest size:(int)size;
- (void)getPhases:(float*)dest size:(int)size;
- (void)getDeltaPhases:(float*)dest size:(int)size;
- (float)accPower;
- (void)setPowerThresholdDB:(float)thresholdDB;
- (void)update:(float)sample
NS_SWIFT_NAME(update(sample:));
- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride
NS_SWIFT_NAME(update(frameData:frameLength:sampleStride:));
- (void)updateConcurrent:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride
NS_SWIFT_NAME(updateConcurrent(frameData:frameLength:sampleStride:));
- (void)setTimeConstant:(float)tau frameLength:(int)frameLength sampleStride:(int)sampleStride sampleRate:(float)sampleRate;
@end
