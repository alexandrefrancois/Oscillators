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
    
    private(set) var s: Float = 0.0
    private(set) var c: Float = 0.0
    private(set) var waveform2Ptr: UnsafeMutableBufferPointer<Float>

    public var phase: Float = 0.0
    public var trackedFrequency: Float = 0.0
    
    public init(targetFrequency: Float, sampleDuration: Float, alpha: Float) {
        let f = Frequencies.closestFrequency(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        let n = 1.0 / (f * sampleDuration)
        let numSamplesInWaveformLocal : Int = Int(n)
        waveform2Ptr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInWaveformLocal)
        waveform2Ptr.initialize(repeating: 0)

        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        setWaveform(waveShape: .sine)
        setCosineWave()
    }
    
    deinit {
        waveform2Ptr.baseAddress?.deinitialize(count: numSamplesInWaveform)
        waveform2Ptr.deallocate()
    }

    func updateWithSample(_ sample: Float) {
        let alphaSample : Float = alpha * sample
        s = omAlpha * s + alphaSample * waveformPtr[phaseIdx]
        c = omAlpha * c + alphaSample * waveform2Ptr[phaseIdx]
        phaseIdx = (phaseIdx + 1) % numSamplesInWaveform
    }
    
    public func update(sample: Float) {
        updateWithSample(sample)
        amplitude = sqrt(s*s + c*c)
   }
    
    public func update(samples: [Float]) {
        for sample in samples {
            updateWithSample(sample)
        }
        amplitude = sqrt(s*s + c*c)
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateWithSample(frameData[sampleIndex])
        }
        amplitude = sqrt(s*s + c*c)
    }
    
    public func updateAndTrack(sample: Float) {
        updateWithSample(sample)
        amplitude = sqrt(s*s + c*c)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(numSamples: 1)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(samples: [Float]) {
        for sample in samples {
            updateWithSample(sample)
        }
        amplitude = sqrt(s*s + c*c)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(numSamples: samples.count)
        } else {
            trackedFrequency = frequency
        }
    }

    public func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateWithSample(frameData[sampleIndex])
        }
        amplitude = sqrt(s*s + c*c)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(numSamples: frameLength)
        } else {
            trackedFrequency = frequency
        }
    }
    
    func updateTrackedFrequency(numSamples: Int) {
        let newPhase = atan2(s,c) // returns value in [-pi,pi]
        var phaseDrift = newPhase - phase
        phase = newPhase
        if phaseDrift <= -Float.pi {
            phaseDrift += twoPi
        } else if phaseDrift > Float.pi {
            phaseDrift -= twoPi
        }

//        trackedFrequency = frequency - phaseDrift / (twoPi * Float(numSamples) * sampleDuration)
        
        let localAlpha = alpha * Float(numSamples)
        let localOmAlpha = 1.0 - localAlpha
        let instantaneousFrequency = frequency - phaseDrift / (twoPi * Float(numSamples) * sampleDuration)
        trackedFrequency = (localOmAlpha * trackedFrequency) + (localAlpha * instantaneousFrequency)
    }
    
    func setCosineWave() {
        let twoPiFrequency : Float = twoPi * frequency
        let delta : Float = twoPiFrequency * sampleDuration
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &waveform2Ptr)
        vForce.cos(waveform2Ptr, result: &waveform2Ptr)
    }

}
