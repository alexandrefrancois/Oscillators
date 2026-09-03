/**
MIT License

Copyright (c) 2022-2025 Alexandre R. J. Francois

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

import Foundation
import Accelerate

fileprivate let twoPi = Float.pi * 2.0
fileprivate let instantaneousFrequencyPowerThreshold = Float(0.000001)

/// An oscillator that resonates with a specific frequency if present in an input signal,
/// i.e. that naturally oscillates with greater amplitude at a given frequency, than at other frequencies.
public class Resonator : ResonatorBase, ResonatorProtocol {

//    public init(frequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil, sampleRate: Float) {
//        super.init(frequency: frequency, sampleRate: sampleRate)
//    }
    
    // override to apply smoothing here
    override func updateDeltaPhase(lcc: Float, lss: Float) {
        // compute current * conjugate(previous)
        // the phase time derivative estimate is the arg of this complex number
        // Smoothing (EWMA) with gamma
        dpc = omGamma * dpc + gamma * (cc * lcc + ss * lss)
        dps = omGamma * dps + gamma * (ss * lcc - cc * lss)
    }
    
    public func update(sample: Float) {
        updateWithSample(sample)
        stabilize() // this is overkill but necessary
    }
    
    public func update(samples: [Float]) {
        for sample in samples {
            updateWithSample(sample)
        }
        stabilize() // this is overkill but necessary
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateWithSample(frameData[sampleIndex])
        }
        stabilize() // this is overkill but necessary
    }
}
