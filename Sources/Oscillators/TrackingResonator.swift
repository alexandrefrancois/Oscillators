/**
MIT License

Copyright (c) 2025 Alexandre R. J. Francois

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
fileprivate let minMaxPower = Float(0.00001)

/// An oscillator that resonates with a specific frequency if present in an input signal,
/// i.e. that naturally oscillates with greater amplitude at a given frequency, than at other frequencies.
public class TrackingResonator : Phasor, TrackingResonatorProtocol {

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

    private(set) var trackFrequencyPowerThreshold = Float(0.001)
    
    // complex: r = c + j s
    private(set) var c: Float = 0.0
    private(set) var s: Float = 0.0

    // Smoothed resonator output
    public private(set) var cc: Float = 0.0
    public private(set) var ss: Float = 0.0
    
    // delta-phase components (not normalized)
    public private(set) var dpc: Float = 1.0
    public private(set) var dps: Float = 0.0
    
    public var resonantFrequency: Float {
        frequency
    }
    
    public private(set) var naturalFrequency: Float
    public func setNaturalFrequency(_ naturalFrequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil){
        self.naturalFrequency = naturalFrequency
        self.alpha = alpha
        self.beta = beta ?? alpha
        self.gamma = gamma ?? alpha
    }
    
    public init(naturalFrequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil, sampleRate: Float) {
        self.naturalFrequency = naturalFrequency
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.beta = beta ?? alpha
        self.omBeta = 1.0 - self.beta
        self.gamma = gamma ?? alpha
        self.omGamma = 1.0 - self.gamma
        super.init(frequency: naturalFrequency, sampleRate: sampleRate)
    }
    
    func updateWithSample(_ sample: Float) {
        let alphaSample : Float = alpha * sample
        c = omAlpha * c + alphaSample * Zc
        s = omAlpha * s + alphaSample * Zs
        // save current values
        let lcc = cc
        let lss = ss
        // update
        cc = omBeta * cc + beta * c
        ss = omBeta * ss + beta * s
        // compute current * conjugate(previous)
        // the phase time derivative estimate is the arg of this complex number
        
        
        // TODO: Question 1 - confirm no smoothing here
        
        // no need to smoothe here?
        dpc = cc * lcc + ss * lss
        dps = ss * lcc - cc * lss

//        // Smoothing (EWMA) with gamma
//        dpc = omGamma * dpc + gamma * (cc * lcc + ss * lss)
//        dps = omGamma * dps + gamma * (ss * lcc - cc * lss)

        // TODO: Question2: figure out what to do here... why this value, what is the impact on dynamics?
        let sigma: Float = alpha / 2
        
        // Update tracking
        if power > trackFrequencyPowerThreshold {
            
            // Explicit frequency computation and back
//            let w = atan2(cc,ss) + 0.00001 * atan2(dps, dpc)
//            updateMultiplier(omega: w)

//            # Rotate W by - alpha * delta_phases
//            # Complex multiplications
//            # still requires abs and power...
//            mSCP = np.abs(conjugate_product[i])
//            nSCP = conjugate_product[i] / mSCP if mSCP > 0 else 1
//            # scaling the angle requires taking power
//            snSCP = np.power(nSCP, -gamma, dtype=complex)
//            W = W * snSCP
            
//            
//            
//            let m = sqrt(dpc * dpc + dps * dps)
//            if m > trackFrequencyPowerThreshold {
//                
//                // take gamma power of complex number dpc + i dps
//                // then update multiplier with that
//                
//                updateMultiplier(c: dpc/m, s: dps/m)
//            }
//            
//            
//
            // TODO: Other implementations - more efficient?
            
            // This is an EWMA with parameter sigma
            self.frequency += sigma * atan2(dps, dpc) * sampleRate / twoPi
            
        } else {
            // go back towards natural frequency
//            let fr = resonantFrequency
//            let df = 0.001 * (naturalFrequency - fr)
//            
//            // Explicit frequency computation and back
//            let w = atan2(cc,ss) + df * twoPi / sampleRate
//            updateMultiplier(omega: w)


//            self.frequency += sigma * (naturalFrequency - frequency)
            self.frequency = naturalFrequency
        }
        
        incrementPhase()
    }
    
    public func update(sample: Float, maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(minMaxPower, maxPower) / 1000.0
        updateWithSample(sample)
        stabilize() // this is overkill but necessary
    }
    
    public func update(samples: [Float], maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(minMaxPower, maxPower) / 1000.0
        for sample in samples {
            updateWithSample(sample)
        }
        stabilize() // this is overkill but necessary
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int, maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(minMaxPower, maxPower) / 1000.0
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateWithSample(frameData[sampleIndex])
        }
        stabilize() // this is overkill but necessary
    }
}
