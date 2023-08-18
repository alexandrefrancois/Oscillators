/**
MIT License

Copyright (c) 2023 Alexandre R. J. Francois

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

/// An oscillator used to generate a periodic signal
public class Generator2 : Oscillator2, GeneratorProtocol {
    private let sineLUT = SineLUT.shared
    
    public init(frequency: Float, sampleDuration: Float, amplitude: Float = 1.0) {
        super.init(frequency: frequency, sampleDuration: sampleDuration)
        self.amplitude = amplitude
    }

    public func getNextSample() -> Float {
        let nextSample = amplitude * sineLUT.sin(phaseIdx: phaseIdx);
        phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        return nextSample
    }
    
    public func getNextSamples(numSamples: Int) -> [Float] {
        var samples = [Float]()
        var samplesToGet = numSamples
        while samplesToGet > 0 {
            samples.append(amplitude * sineLUT.sin(phaseIdx: phaseIdx))
            samplesToGet -= 1
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        }
        return samples
    }
    
    public func getNextSamples(samples: inout [Float]) {
        var sampleIdx = 0
        while sampleIdx < samples.count {
            samples[sampleIdx] = amplitude * sineLUT.sin(phaseIdx: phaseIdx)
            sampleIdx += 1
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        }
    }
}
