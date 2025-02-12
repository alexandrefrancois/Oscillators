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

fileprivate let twoPi = Float.pi * 2.0

/// Oscillator base class:
/// an oscillator is characterized by its frequency and amplitude.
/// Waveform values are computed recursively with a complex phasor.
/// Incremental calculations depend on frequency and sampling rate.
public class Oscillator : Phasor, OscillatorProtocol {
    public var amplitude: Float = 1.0
    public var sample : Float {
        amplitude * Zc
    }
    
    public init(frequency: Float, sampleRate: Float, amplitude: Float = 1.0) {
        super.init(frequency: frequency, sampleRate: sampleRate)
        self.amplitude = amplitude
    }
    
    public func getNextSample() -> Float {
        let nextSample = sample;
        incrementPhase()
        stabilize() // this is overkill but necessary
        return nextSample
    }
    
    public func getNextSamples(numSamples: Int) -> [Float] {
        var samples = [Float]()
        var samplesToGet = numSamples
        while samplesToGet > 0 {
            samples.append(sample)
            samplesToGet -= 1
            incrementPhase()
        }
        stabilize()
        return samples
    }
    
    public func getNextSamples(samples: inout [Float]) {
        var sampleIdx = 0
        while sampleIdx < samples.count {
            samples[sampleIdx] = sample
            sampleIdx += 1
            incrementPhase()
        }
        stabilize()
    }
}
