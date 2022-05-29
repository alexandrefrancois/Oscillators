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
import Accelerate

fileprivate let twoPi = Float.pi * 2.0
fileprivate let trackFrequencyThreshold = Float(0.001)

/// A single oscillator, computations use the Accelerate framework with swift arrays
public class ResonatorSafe : Oscillator, ResonatorProtocol {
    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0
    
    public var timeConstant : Float {
        sampleDuration / alpha
    }

    public var trackedFrequency: Float = 0.0
    private var maxIdx: Int = 0

    public private(set) var allPhases = [Float]()
    private var leftTerm = [Float]()
    private var rightTerm = [Float]()
    
    public init(targetFrequency: Float, sampleDuration: Float, alpha: Float) {
        self.alpha = alpha
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)

        self.allPhases = [Float](repeating: 0, count: numSamplesInWaveform)
        leftTerm = [Float](repeating: 0, count: numSamplesInWaveform)
        rightTerm = [Float](repeating: 0, count: numSamplesInWaveform)
        
        setWaveform(waveShape: .sine)
    }
        
    func updateAllPhases(sample: Float) {
        let alphaSample : Float = alpha * sample
                
        vDSP.multiply(omAlpha, allPhases, result: &leftTerm)
        
        let complement = numSamplesInWaveform - phaseIdx
        vDSP.multiply(alphaSample, waveformPtr[..<complement], result: &rightTerm[phaseIdx...])
        vDSP.multiply(alphaSample, waveformPtr[complement...], result: &rightTerm[..<phaseIdx])
        
        vDSP.add(leftTerm, rightTerm, result: &allPhases)
        
        phaseIdx = (phaseIdx + 1) % numSamplesInWaveform
    }
    
    public func update(sample: Float) {
        // input amplitude is in [-1. 1]
        updateAllPhases(sample: sample)
   }
    
    public func update(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
    }
    
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
    }
    
    public func updateAndTrack(sample: Float) {
        // input amplitude is in [-1. 1]
        updateAllPhases(sample: sample)
        var maxIdx: UInt
        (maxIdx, self.amplitude) = vDSP.indexOfMaximum(allPhases)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: Int(maxIdx), numSamples: 1)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
        var maxIdx: UInt
        (maxIdx, self.amplitude) = vDSP.indexOfMaximum(allPhases)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: Int(maxIdx), numSamples: samples.count)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
        var maxIdx: UInt
        (maxIdx, self.amplitude) = vDSP.indexOfMaximum(allPhases)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: Int(maxIdx), numSamples: frameLength)
        } else {
            trackedFrequency = frequency
        }
    }

    func updateTrackedFrequency(newMaxIdx: Int, numSamples: Int) {
        var numSamplesDrift = (newMaxIdx - maxIdx)
        if numSamplesDrift < -numSamplesInWaveform / 2 {
            numSamplesDrift += numSamplesInWaveform - 1
        } else if numSamplesDrift > numSamplesInWaveform / 2 {
            numSamplesDrift -= numSamplesInWaveform - 1
        }
        let localAlpha = alpha * Float(numSamples)
        let localOmAlpha = 1.0 - localAlpha
        let instantaneousFrequency = 1.0 / (sampleDuration * Float(numSamplesInWaveform) * (1.0 - Float(numSamplesDrift) / Float(numSamples)))
        trackedFrequency = (localOmAlpha * trackedFrequency) + (localAlpha * instantaneousFrequency)
        maxIdx = newMaxIdx
    }
}
