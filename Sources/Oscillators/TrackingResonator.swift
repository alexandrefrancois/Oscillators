/**
MIT License

Copyright (c) 2025-2026 Alexandre R. J. Francois

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
fileprivate let minMaxPower = Float(0.001)

/// An oscillator that resonates with a specific frequency if present in an input signal,
/// and adjust its resonant frequency to track the actual frequency of the signal component
public class TrackingResonator : ResonatorBase, TrackingResonatorProtocol {
    public static func gammaHeuristic(frequency: Float, sampleRate: Float, k: Float = 1, n: Float = 1) -> Float {
        Resonator.alphaHeuristic(frequency: frequency, sampleRate: sampleRate, k: k, n: n) / 2.0
    }

    public var resonantFrequency: Float {
        frequency
    }
    
    // Changing the natural frequency will most likely require to set alpha, beta and gamma accordingly
    public func setNaturalFrequency(_ naturalFrequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil){
        let naturalOmega = -naturalFrequency / sampleRateOverTwoPi
        setNaturalW(c: cos(naturalOmega), s: sin(naturalOmega))
        self.alpha = alpha
        self.beta = beta ?? alpha
        self.gamma = gamma ?? alpha
    }

    public var naturalFrequency: Float {
        get {
            -atan2(naturalWs, naturalWc) * sampleRateOverTwoPi
        }
    }
    
    public var naturalOmega: Float {
        get {
            atan2(naturalWs, naturalWc)
        }
    }
    
    var naturalWc: Float
    var naturalWs: Float

//    public func setNaturalFrequency(_ naturalFrequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil){
//        self.naturalFrequency = naturalFrequency
//        self.alpha = alpha
//        self.beta = beta ?? alpha
//        self.gamma = gamma ?? alpha
//    }
    
    private(set) var trackFrequencyPowerThreshold = Float(0.001)

    public init(naturalFrequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil, sampleRate: Float) {
        let naturalOmega = -naturalFrequency / (sampleRate / twoPi)
        self.naturalWc = cos(naturalOmega)
        self.naturalWs = sin(naturalOmega)
        super.init(frequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, sampleRate: sampleRate)
    }
        
    func updateTracking() {
        // Update tracking
        if power > trackFrequencyPowerThreshold {
            // This is an EWMA with parameter gamma
            omega -= gamma * atan2(dps, dpc)
        } else {
            // go back to natural frequency
            self.restoreNaturalW()
        }
    }
    
    override func updateWithSample(_ sample: Float) {
        // save current values
        let lcc = cc
        let lss = ss
        updateResonatorWithSample(sample)
        updateDeltaPhase(lcc: lcc, lss: lss)
        updateTracking()
        incrementPhase()
    }
        
    public func update(sample: Float, maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(minMaxPower, maxPower) / Float(1000.0)
        updateWithSample(sample)
        stabilize()
    }
    
    public func update(samples: [Float], maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(minMaxPower, maxPower) / Float(1000.0)
        for sample in samples {
            updateWithSample(sample)
        }
        stabilize()
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int, maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(minMaxPower, maxPower) / Float(1000.0)
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateWithSample(frameData[sampleIndex])
        }
        stabilize()
    }
    
    func setNaturalW(c: Float, s: Float) {
        naturalWc = c
        naturalWs = s
    }

    func restoreNaturalW() {
        setW(c: naturalWc, s: naturalWs)
    }
}
