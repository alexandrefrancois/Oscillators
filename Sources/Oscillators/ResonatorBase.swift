/**
MIT License

Copyright (c) 2026 Alexandre R. J. Francois

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
public class ResonatorBase : Phasor {
    public static func alphaHeuristic(frequency: Float, sampleRate: Float, k: Float = 1, n: Float = 1) -> Float {
        1 - exp(-frequency / (sampleRate * k * pow(log10(1+frequency), n)))
    }

    public var power: Float {
        cc*cc + ss*ss
    }
    public var amplitude: Float {
        sqrt(cc*cc + ss*ss)
    }
    public var phase: Float {
        atan2(ss, cc)
    }
    public var phaseComps: (cos: Float, sin: Float) {
        let mag = sqrt(cc*cc + ss*ss)
        return (cc/mag, ss/mag)
    }
    public var deltaPhase: Float {
        atan2(dps, dpc)
    }
    public var deltaPhaseComps: (cos: Float, sin: Float) {
        let mag = sqrt(dps*dps + dpc*dpc)
        return (dpc/mag, dps/mag)
    }
    
    public var instantaneousFrequency: Float {
        if power < instantaneousFrequencyPowerThreshold {
            return frequency
        }
        return frequency + atan2(dps,dpc) * sampleRate / twoPi
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

    public var gamma: Float {
        didSet {
            omGamma = 1.0 - gamma
        }
    }
    private(set) var omGamma : Float = 0.0

    // complex: r = c + j s
    var c: Float = 0.0
    var s: Float = 0.0

    // Smoothed resonator output
    public internal(set) var cc: Float = 0.0
    public internal(set) var ss: Float = 0.0
    
    // delta-phase components (not normalized)
    public internal(set) var dpc: Float = 0.0
    public internal(set) var dps: Float = 0.0
    
    public init(frequency: Float, sampleRate: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.beta = beta ?? alpha
        self.omBeta = 1.0 - self.beta
        self.gamma = gamma ?? alpha
        self.omGamma = 1.0 - self.gamma
        super.init(frequency: frequency, sampleRate: sampleRate)
    }
    
    func updateResonatorWithSample(_ sample: Float) {
        let alphaSample : Float = alpha * sample
        c = omAlpha * c + alphaSample * Zc
        s = omAlpha * s + alphaSample * Zs
        // update
        cc = omBeta * cc + beta * c
        ss = omBeta * ss + beta * s
    }
    
    // no smoothing by default
    func updateDeltaPhase(lcc: Float, lss: Float) {
        // compute current * conjugate(previous)
        // the phase time derivative estimate is the arg of this complex number
        // no smoothing
        dpc = cc * lcc + ss * lss
        dps = ss * lcc - cc * lss
    }
    
    func updateWithSample(_ sample: Float) {
        // save current values
        let lcc = cc
        let lss = ss
        updateResonatorWithSample(sample)
        updateDeltaPhase(lcc: lcc, lss: lss)
        incrementPhase()
    }    
}
