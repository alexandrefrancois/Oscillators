/**
MIT License

Copyright (c) 2024 Alexandre R. J. Francois

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

// Wrapper for the ResonatorBank class
@interface ResonatorBankVecCpp : NSObject
- (instancetype)initWithNumResonators:(int)numResonators frequencies:(const float*)frequencies alphas:(const float*)alphas sampleRate:(float)sampleRate;
- (float)sampleRate;
- (int)numResonators;
- (float)frequencyValue:(int)index;
- (float)alphaValue:(int)index;
- (float)timeConstantValue:(int)index;
- (void)copyPowers:(float*)dest size:(int)size; // this is a bit ugly but avoids memory management issues
- (float)powerValue:(int)index;
- (void)copyAmplitudes:(float*)dest size:(int)size; // this is a bit ugly but avoids memory management issues
- (float)amplitudeValue:(int)index;
- (void)update:(float)sample
NS_SWIFT_NAME(update(sample:));
- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride
NS_SWIFT_NAME(update(frameData:frameLength:sampleStride:));
- (void)update:(float*)frame frameLength:(int)frameLength sampleStride:(int)sampleStride powers:(float*)powers amplitudes:(float*)amplitudes
NS_SWIFT_NAME(update(frameData:frameLength:sampleStride:powers:amplitudes:));
@end

