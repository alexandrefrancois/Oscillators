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

import Foundation

/// An oscillator used to generate a periodic signal
public class Generator : Oscillator, GeneratorProtocol {
    public init(targetFrequency: Float, sampleDuration: Float, waveShape: WaveShape, amplitude: Float = 1.0) {
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        setWaveform(waveShape: waveShape)
        self.amplitude = amplitude
    }

    public func getNextSample() -> Float {
        let nextSample = amplitude * waveformPtr[phaseIdx];
        phaseIdx = (phaseIdx + 1) % waveformPtr.count;
        return nextSample
    }
    
    public func getNextSamples(numSamples: Int) -> [Float] {
        var samples = [Float]()
        var samplesToGet = numSamples
        while samplesToGet > 0 {
            samples.append(amplitude * waveformPtr[phaseIdx])
            samplesToGet -= 1
            phaseIdx = (phaseIdx + 1) % waveformPtr.count
        }
        return samples
    }
    
    public func getNextSamples(samples: inout [Float]) {
        var sampleIdx = 0
        while sampleIdx < samples.count {
            samples[sampleIdx] = amplitude * waveformPtr[phaseIdx]
            sampleIdx += 1
            phaseIdx = (phaseIdx + 1) % waveformPtr.count
        }
    }
}
