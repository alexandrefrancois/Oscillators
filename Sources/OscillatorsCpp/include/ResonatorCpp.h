/**
MIT License

Copyright (c) 2022-2023 Alexandre R. J. Francois

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
#import "OscillatorCpp.h"

// Wrapper for the Resonator class
@interface ResonatorCpp : OscillatorCpp
- (instancetype)initWithTargetFrequency:(float)frequency sampleDuration:(float)sampleDuration alpha:(float)alpha;
- (float)alpha;
- (void)setAlpha:(float)alpha;
- (float)omAlpha;
- (float)timeConstant;
- (float)s;
- (float)c;
- (float)phase;
- (float)trackedFrequency;
- (void)updateWithSample:(float)sample
NS_SWIFT_NAME(updateWithSample(value:));
- (void)update:(float)sample
NS_SWIFT_NAME(update(sample:));
- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride
NS_SWIFT_NAME(update(frameData:frameLength:sampleStride:));
- (void)updateAndTrack:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride
NS_SWIFT_NAME(updateAndTrack(frameData:frameLength:sampleStride:));
- (float)waveform2Value:(int)index;
@end
