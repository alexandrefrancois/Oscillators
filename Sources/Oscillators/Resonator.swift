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

/// An oscillator that resonates with a specific frequency if present in an input signal,
/// i.e. that naturally oscillates with greater amplitude at a given frequency, than at other frequencies.
public class Resonator : Oscillator, ResonatorProtocol {
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

    public var allPhases: [Float] {
        allPhasesPtr!.map { $0 }
    }
    public private(set) var allPhasesPtr: UnsafeMutableBufferPointer<Float>?
    
    public private(set) var leftTermPtr: UnsafeMutableBufferPointer<Float>?
    public private(set) var rightTermPtr: UnsafeMutableBufferPointer<Float>?
    
    public init(targetFrequency: Float, sampleDuration: Float, alpha: Float) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        setWaveform(waveShape: .sine)
        allPhasesPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInWaveform)
        allPhasesPtr!.initialize(repeating: 0)
        leftTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInWaveform)
        leftTermPtr!.initialize(repeating: 0)
        rightTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInWaveform)
        rightTermPtr!.initialize(repeating: 0)
    }
    
    deinit {
        allPhasesPtr!.baseAddress?.deinitialize(count: numSamplesInWaveform)
        allPhasesPtr!.deallocate()
        leftTermPtr!.baseAddress?.deinitialize(count: numSamplesInWaveform)
        leftTermPtr!.deallocate()
        rightTermPtr!.baseAddress?.deinitialize(count: numSamplesInWaveform)
        rightTermPtr!.deallocate()
    }
    
    func updateAllPhases(sample: Float) {
        var alphaSample : Float = alpha * sample
        vDSP_vsmul(allPhasesPtr!.baseAddress!, 1, &omAlpha, leftTermPtr!.baseAddress!, 1, vDSP_Length(numSamplesInWaveform))
        vDSP_vsmul(waveformPtr.baseAddress! + phaseIdx, 1, &alphaSample, rightTermPtr!.baseAddress!, 1, vDSP_Length(waveformPtr.count - phaseIdx))
        vDSP_vsmul(waveformPtr.baseAddress!, 1, &alphaSample, rightTermPtr!.baseAddress! + (waveformPtr.count - phaseIdx), 1, vDSP_Length(phaseIdx))
        vDSP_vadd(leftTermPtr!.baseAddress!, 1, rightTermPtr!.baseAddress!, 1, allPhasesPtr!.baseAddress!, 1, vDSP_Length(numSamplesInWaveform))
        phaseIdx = (phaseIdx + 1) % numSamplesInWaveform
    }
    
    public func update(sample: Float) {
        updateAllPhases(sample: sample)
        vDSP_maxv(allPhasesPtr!.baseAddress!, 1, &amplitude, vDSP_Length(numSamplesInWaveform))
   }
    
    public func update(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
        vDSP_maxv(allPhasesPtr!.baseAddress!, 1, &amplitude, vDSP_Length(numSamplesInWaveform))
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
        vDSP_maxv(allPhasesPtr!.baseAddress!, 1, &amplitude, vDSP_Length(numSamplesInWaveform))
    }
    
    public func updateAndTrack(sample: Float) {
        updateAllPhases(sample: sample)
        var idx: vDSP_Length = 0
        vDSP_maxvi(allPhasesPtr!.baseAddress!, 1, &amplitude, &idx, vDSP_Length(numSamplesInWaveform))
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: Int(idx), numSamples: 1)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
        var idx: vDSP_Length = 0
        vDSP_maxvi(allPhasesPtr!.baseAddress!, 1, &amplitude, &idx, vDSP_Length(numSamplesInWaveform))
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: Int(idx), numSamples: samples.count)
        } else {
            trackedFrequency = frequency
        }
    }

    public func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
        var idx: vDSP_Length = 0
        vDSP_maxvi(allPhasesPtr!.baseAddress!, 1, &amplitude, &idx, vDSP_Length(numSamplesInWaveform))
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: Int(idx), numSamples: frameLength)
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
