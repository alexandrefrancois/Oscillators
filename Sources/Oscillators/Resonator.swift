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
fileprivate let trackFrequencyThreshold = Float(0.001)

/// An oscillator that resonates with a specific frequency if present in an input signal,
/// i.e. that naturally oscillates with greater amplitude at a given frequency, than at other frequencies.
public class Resonator : Phasor, ResonatorProtocol {
    public var power: Float {
        cc*cc + ss*ss
    }
    public var amplitude: Float {
        sqrt(cc*cc + ss*ss)
    }
    
    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0
    
    public var beta: Float {
        didSet {
            omBeta = 1.0 - beta
        }
    }
    private(set) var omBeta : Float = 0.0
    
    // complex: r = c + j s
    private(set) var c: Float = 0.0
    private(set) var s: Float = 0.0

    // Smoothed resonator output
    private(set) var cc: Float = 0.0
    private(set) var ss: Float = 0.0

    public var phase: Float = 0.0
    public var trackedFrequency: Float = 0.0
    
    public init(frequency: Float, alpha: Float, beta: Float? = nil, sampleRate: Float) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.beta = beta ?? alpha
        self.omBeta = 1.0 - self.beta
        super.init(frequency: frequency, sampleRate: sampleRate)
    }
    
    func updateWithSample(_ sample: Float) {
        let alphaSample : Float = alpha * sample
        c = omAlpha * c + alphaSample * Zc
        s = omAlpha * s + alphaSample * Zs
        cc = omBeta * cc + beta * c
        ss = omBeta * ss + beta * s
        incrementPhase()
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
    
    public func updateAndTrack(sample: Float) {
        updateWithSample(sample)
        stabilize() // this is overkill but necessary
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
        stabilize() // this is overkill but necessary
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
        stabilize() // this is overkill but necessary
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(numSamples: frameLength)
        } else {
            trackedFrequency = frequency
        }
    }
    
    func updateTrackedFrequency(numSamples: Int) {
        let newPhase = atan2(ss,cc) // returns value in [-pi,pi]
        var phaseDrift = newPhase - phase
        phase = newPhase
        if phaseDrift <= -Float.pi {
            phaseDrift += twoPi
        } else if phaseDrift > Float.pi {
            phaseDrift -= twoPi
        }
        
//        let localAlpha = alpha * Float(numSamples)
//        let localOmAlpha = 1.0 - localAlpha
//        let instantaneousFrequency = frequency - phaseDrift * sampleRate / (twoPi * Float(numSamples))
//        trackedFrequency = (localOmAlpha * trackedFrequency) + (localAlpha * instantaneousFrequency)
        
        trackedFrequency = frequency - phaseDrift * sampleRate / (twoPi * Float(numSamples))
    }
    
}
