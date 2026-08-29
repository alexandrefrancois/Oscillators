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
#import "ResonatorBaseCpp.h"

#import "TrackingRuleCpp.h"

// Wrapper for the TrackingResonator class
@interface TrackingResonatorCpp : ResonatorBaseCpp
- (instancetype)initWithNaturalFrequency:(float)naturalFrequency alpha:(float)alpha beta:(float)beta gamma:(float)gamma trackingRule:(TrackingRuleCpp)trackingRule sampleRate:(float)sampleRate;
- (float)naturalFrequency;
- (void)setNaturalFrequency:(float)frequency alpha:(float)alpha beta:(float)beta gamma:(float)gamma;
- (float)resonantFrequency;
- (void)update:(float)sample maxPower:(float)maxPower thresholdDivider:(float)thresholdDivider
NS_SWIFT_NAME(update(sample:maxPower:thresholdDivider:));
- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride maxPower:(float)maxPower thresholdDivider:(float)thresholdDivider
NS_SWIFT_NAME(update(frameData:frameLength:sampleStride:maxPower:thresholdDivider:));
@end
