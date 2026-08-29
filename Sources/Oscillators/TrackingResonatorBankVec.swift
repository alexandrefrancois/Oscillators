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
import simd

fileprivate let twoPi = Float.pi * 2.0
fileprivate let minPowerThreshold = Float(1e-6)
fileprivate let minimumResidualMagnitudeSquared = Float(1e-20)

/// A bank of independent tracking resonators implemented as a single array, computations use the Accelerate framework with manual memory management (unsafe pointers)
public class TrackingResonatorBankVec {
    public static func alphasHeuristic(frequencies: [Float], sampleRate: Float, k: Float = 1) -> [Float] {
        frequencies.map { frequency in
            Resonator.alphaHeuristic(frequency: frequency, sampleRate: sampleRate, k: k)
        }
    }
    
    public private(set) var sampleRate : Float
    
    public private(set) var numResonators : Int
    public private(set) var naturalFrequencies : [Float]
    
    public var powers : [Float] {
        return [Float](powersPtr)
    }
    public var amplitudes : [Float] {
        vForce.sqrt(powersPtr)
    }
    public var phases : [Float] {
        var phases = [Float](repeating: 0, count: numResonators)
        vDSP.phase(R, result: &phases)
        return phases
    }
    public var omegas : [Float] {
        var omegas = [Float](repeating: 0, count: numResonators)
        // Compute the angular velocities from W
        vDSP.phase(W, result: &omegas)
        return omegas
    }
    public var resonantFrequencies: [Float] {
        var frequencies = [Float](repeating: 0, count: numResonators)
        // Compute the resonant frequencies from W
        // f = -omega * sampleRate / twoPi
        vDSP.phase(W, result: &frequencies)
        vDSP.multiply(-sampleRate / twoPi, frequencies, result: &frequencies)
        return frequencies
    }
    
    // max power accumulation
    private(set) var sigma: Float = 1.0 {
        didSet {
            omSigma = 1.0 - sigma
        }
    }
    private(set) var omSigma : Float = 0.0
    public private(set) var accPower: Float = 0.0001
    
    public private(set) var alphas : [Float] // can be tuned independently for each frequency
    private(set) var omAlphas : [Float] // can be tuned independently for each frequency
    private(set) var betas : [Float]
    private(set) var omBetas : [Float]
    private(set) var gammas : [Float]
    private(set) var omGammas : [Float]
    
    private var twoNumResonators : Int
    
    /// Accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    private var rPtr : UnsafeMutableBufferPointer<Float>
    /// Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    private var rrPtr : UnsafeMutableBufferPointer<Float>
    /// Vector of complex representation of accumulated resonance values
    private var R : DSPSplitComplex
    
    /// Previous Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    private var rrmPtr : UnsafeMutableBufferPointer<Float>
    /// Vector of complex representation of previous accumulated resonance values
    private var Rm : DSPSplitComplex
    
    /// Phase derivative components:
    /// current multiplied by conjugate of previous, non-interlaced real (cos) | imaginary (sin) parts
    /// The delta phase is the arg of this complex number
    private var dPtr : UnsafeMutableBufferPointer<Float>
    /// Vector of complex representation of current multiplied by conjugate of previous
    private var D : DSPSplitComplex
    
    /// Phasors
    private var zPtr : UnsafeMutableBufferPointer<Float>
    /// Vector of complex representation of phasor values
    private var Z : DSPSplitComplex
    /// Phasor multipliers
    private var wPtr : UnsafeMutableBufferPointer<Float>
    /// Vector of complex representation of phasor multiplier values
    private var W : DSPSplitComplex
    
    /// hold sample value * alphas
    private var alphasSample : UnsafeMutableBufferPointer<Float>
    
    private var nwPtr : UnsafeMutableBufferPointer<Float>
    private var nW : DSPSplitComplex
    private var naturalOmegasPtr : UnsafeMutableBufferPointer<Float>

    private var powersPtr : UnsafeMutableBufferPointer<Float>
    private var maskPtr : UnsafeMutableBufferPointer<Float>
    private var inverseMaskPtr : UnsafeMutableBufferPointer<Float>
    
    /// Squared magnitudes buffer (ntermediate calculations)
    private var smPtr : UnsafeMutableBufferPointer<Float>
    /// Reverse square root buffer (intermediate calculations)
    private var rsqrtPtr : UnsafeMutableBufferPointer<Float>
    
    private let trackingRule: TrackingRule
    private(set) var trackingPowerThresholdRatio = Float(0.001)
    public func setPowerThresholdDB(_ thresholdDB: Float) {
        trackingPowerThresholdRatio = pow(10.0, thresholdDB / 10.0)
    }

    public init(naturalFrequencies: [Float], sampleRate: Float, alphas: [Float], betas: [Float]? = nil, gammas: [Float]?, trackingRule: TrackingRule, thresholdDB: Float) {
        // check that frequencies and alphas have the same size
        assert(naturalFrequencies.count == alphas.count)
        
        self.sampleRate = sampleRate
        
        // initialize from passed natural frequencies
        self.naturalFrequencies = naturalFrequencies
        self.numResonators = naturalFrequencies.count
        
        // These must be 2 * numResonators size
        self.alphas = alphas + alphas
        self.omAlphas = vDSP.add(multiplication: (self.alphas, -1.0), 1.0)
        if let betas = betas {
            self.betas = betas + betas
            self.omBetas = vDSP.add(multiplication: (self.betas, -1.0), 1.0)
        } else {
            self.betas = self.alphas
            self.omBetas = self.omAlphas
        }
        if let gammas = gammas {
            self.gammas = gammas + gammas
            self.omGammas = vDSP.add(multiplication: (self.gammas, -1.0), 1.0)
        } else {
            self.gammas = vDSP.divide(self.alphas, 2.0)
            self.omGammas = vDSP.add(multiplication: (self.gammas, -1.0), 1.0)
        }
        self.trackingRule = trackingRule
        self.trackingPowerThresholdRatio = pow(10.0, thresholdDB / 10.0)

        twoNumResonators = 2 * numResonators
        
        // setup resonators
        rPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        rPtr.initialize(repeating: 0.0)
        rrPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        rrPtr.initialize(repeating: 0.0)
        R = DSPSplitComplex(realp: rrPtr.baseAddress!,
                            imagp: rrPtr.baseAddress! + numResonators)
        
        rrmPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        rrmPtr.initialize(repeating: 0.0)
        Rm = DSPSplitComplex(realp: rrmPtr.baseAddress!,
                             imagp: rrmPtr.baseAddress! + numResonators)
        
        dPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        dPtr.initialize(repeating: 0.0)
        D = DSPSplitComplex(realp: dPtr.baseAddress!,
                            imagp: dPtr.baseAddress! + numResonators)
        
        zPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        zPtr.initialize(repeating: 0.0)
        Z = DSPSplitComplex(realp: zPtr.baseAddress!,
                            imagp: zPtr.baseAddress! + numResonators)
        vDSP_vfill([1.0], Z.realp, 1, vDSP_Length(numResonators))
        
        let minusTwoPiOverSampleRate = -twoPi / sampleRate
        nwPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        nwPtr.initialize(repeating: minusTwoPiOverSampleRate)
        nW = DSPSplitComplex(realp: nwPtr.baseAddress!,
                             imagp: nwPtr.baseAddress! + numResonators)
        
        // calculate natural omegas
        // multiply -2 * PI / sampleRate by frequency for each resonator
        vDSP_vmul(nW.realp, 1,
                  naturalFrequencies, 1,
                  nW.realp, 1,
                  vDSP_Length(numResonators))
        vDSP_vmul(nW.imagp, 1,
                  naturalFrequencies, 1,
                  nW.imagp, 1,
                  vDSP_Length(numResonators))

        // initialize natural omegas
        // needed for ewma omegas tracking rule
        naturalOmegasPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        memcpy(naturalOmegasPtr.baseAddress, nwPtr.baseAddress, MemoryLayout<Float>.size * numResonators)
        
        // then calculate cos and sin
        var count : Int32 = Int32(numResonators)
        vvcosf(nW.realp, nW.realp, &count)
        vvsinf(nW.imagp, nW.imagp, &count)

        // initialize W with nW
        wPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        W = DSPSplitComplex(realp: wPtr.baseAddress!,
                            imagp: wPtr.baseAddress! + numResonators)
        memcpy(wPtr.baseAddress, nwPtr.baseAddress, MemoryLayout<Float>.size * twoNumResonators)
        
        powersPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        maskPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        inverseMaskPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        
        alphasSample = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        smPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        rsqrtPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
    }
    
    deinit {
        rPtr.deallocate()
        rrPtr.deallocate()
        rrmPtr.deallocate()
        dPtr.deallocate()
        zPtr.deallocate()
        wPtr.deallocate()
        alphasSample.deallocate()
        nwPtr.deallocate()
        naturalOmegasPtr.deallocate()
        powersPtr.deallocate()
        maskPtr.deallocate()
        inverseMaskPtr.deallocate()
        smPtr.deallocate()
        rsqrtPtr.deallocate()
    }
    
    /// Update all resonators in parallel
    func update(sample: Float) {
        var sampleVar = sample
        vDSP_vsmul(alphas, 1, &sampleVar, alphasSample.baseAddress!, 1, vDSP_Length(twoNumResonators));
        
        // Resonator
        vDSP_vmma(rPtr.baseAddress!, 1,
                  omAlphas, 1,
                  zPtr.baseAddress!, 1,
                  alphasSample.baseAddress!, 1,
                  rPtr.baseAddress!, 1,
                  vDSP_Length(twoNumResonators))
        
        // Smoothing using beta
        vDSP_vmma(rrPtr.baseAddress!, 1,
                  omBetas, 1,
                  rPtr.baseAddress!, 1,
                  betas, 1,
                  rrPtr.baseAddress!, 1,
                  vDSP_Length(twoNumResonators))
        
        // Compute squared magnitudes
        vDSP_zvmags(&R, 1,
                    powersPtr.baseAddress!, 1,
                    vDSP_Length(numResonators))
        
        // Update accPower
        var maxPower = Float(0.25)
        vDSP_maxv(powersPtr.baseAddress!, 1,
                  &maxPower,
                  vDSP_Length(numResonators))
        accPower = (omSigma * accPower) + (sigma * maxPower)

        // Update phase derivatives
        // actually compute the opposite so that we can justs add later
        vDSP_zvmul(&R, 1,
                   &Rm, 1,
                   &D, 1,
                   vDSP_Length(numResonators),
                   -1)
        
        // Save previous smoothed value
        _ = rrmPtr.initialize(from: rrPtr)
        
//        let trackingPowerThreshold = max(minPowerThreshold, accPower * trackingPowerThresholdRatio)
        let trackingPowerThreshold = accPower * trackingPowerThresholdRatio

        switch trackingRule {
        case .ewma: // update via omegas
            
            // Compute angle from D
            // store in second half of dPtr
            vDSP_zvphas(&D, 1,
                        dPtr.baseAddress! + numResonators, 1,
                        vDSP_Length(numResonators))
            
            // Compute dw angle from W
            // store in first half of dPtr
            vDSP_zvphas(&W, 1,
                        dPtr.baseAddress!, 1,
                        vDSP_Length(numResonators))
            
            // Add dw
            // store in first half of dPtr
            vDSP_vma(dPtr.baseAddress! + numResonators, 1,
                     gammas, 1,
                     dPtr.baseAddress!, 1,
                     dPtr.baseAddress!, 1,
                     vDSP_Length(numResonators))

            // Single pass threshold and merge
            // output is tracked or natural frequencies in first half of dPtr
            Self.fuseThresholdAndMerge(
                powersPtr: powersPtr,
                dPtr: dPtr,
                naturalOmegasPtr: naturalOmegasPtr,
                threshold: trackingPowerThreshold)
            // at this point the first half of dPtr contains the tracked or natural omegas,
            
            // Update W
            var count : Int32 = Int32(numResonators)
            vvcosf(W.realp, dPtr.baseAddress!, &count)
            vvsinf(W.imagp, dPtr.baseAddress!, &count)
            
            break

            
        case .normalizedChord:
            
//            let residualMagnitudeSquared = dpc * dpc + dps * dps
//            guard residualMagnitudeSquared > minimumResidualMagnitudeSquared,
//                  residualMagnitudeSquared.isFinite
//            else { return }
//            let inverseResidualMagnitude = 1.0 / sqrt(residualMagnitudeSquared)
//            rotateW(c: omGamma + gamma * dpc * inverseResidualMagnitude,
//                    s: -gamma * dps * inverseResidualMagnitude)

            // inverse magnitude of D
            vDSP.squareMagnitudes(D, result: &smPtr)
            // use reciprocal square root
            vForce.rsqrt(smPtr, result: &rsqrtPtr)
            // normalize
            vDSP.multiply(D, by: rsqrtPtr, result: &D)
            
            // calculate error
            // multiply both real part and imaginary part by gammas
            vDSP_vmul(dPtr.baseAddress!, 1,
                      gammas, 1,
                      dPtr.baseAddress!, 1,
                      vDSP_Length(twoNumResonators))

            // real part: omGamma + gamma * dpc * inverseResidualMagnitude
            // add 1-gamma to real part
            vDSP_vadd(dPtr.baseAddress!, 1, // D.realp, 1,
                      omGammas, 1,
                      dPtr.baseAddress!, 1, // D.realp, 1,
                      vDSP_Length(numResonators))
            // imaginary part: -gamma * dps * inverseResidualMagnitude
            // all done - D is already conjugate
                        
            // Calculate corrected Ws, store in D
            vDSP_zvmul(&D, 1,
                       &W, 1,
                       &D, 1,
                       vDSP_Length(numResonators),
                       1)

            // Single pass threshold and merge
            // input powers and D
            // output W
            Self.fuseThresholdAndMerge(powersPtr: powersPtr, D: D, nW: nW, W: W, threshold: trackingPowerThreshold)
            
            // Is this really necessary?
//            // normalize W
//            vDSP.squareMagnitudes(W, result: &smPtr)
//            // use reciprocal square root
//            vForce.rsqrt(smPtr, result: &rsqrtPtr)
//            vDSP.multiply(W, by: rsqrtPtr, result: &W)
            
            break
            
        case .tangent:
            
//            let residualMagnitudeSquared = dpc * dpc + dps * dps
//            guard residualMagnitudeSquared > minimumResidualMagnitudeSquared,
//                  residualMagnitudeSquared.isFinite
//            else { return }
//            let inverseResidualMagnitude = 1.0 / sqrt(residualMagnitudeSquared)
//            rotateW(c: 1.0,
//                    s: -gamma * dps * inverseResidualMagnitude)

            // inverse magnitude of D
            vDSP.squareMagnitudes(D, result: &smPtr)
            // use reciprocal square root
            vForce.rsqrt(smPtr, result: &rsqrtPtr)
            // normalize
            vDSP.multiply(D, by: rsqrtPtr, result: &D)
            
            // set real part to 1.0
            D.realp.initialize(repeating: 1.0, count: numResonators)
            // imaginary part: -gamma * dps * inverseResidualMagnitude
            // multiply by gamma, D is already conjugate
            vDSP_vmul(dPtr.baseAddress!.advanced(by: numResonators), 1,
                      gammas, 1,
                      dPtr.baseAddress!.advanced(by: numResonators), 1,
                      vDSP_Length(numResonators))
            
            // Calculate corrected Ws, store in D
            vDSP_zvmul(&D, 1,
                       &W, 1,
                       &D, 1,
                       vDSP_Length(numResonators),
                       1)

            // Single pass threshold and merge
            // input powers and D
            // output W
            Self.fuseThresholdAndMerge(powersPtr: powersPtr, D: D, nW: nW, W: W, threshold: trackingPowerThreshold)
            
            // Is this really necessary?
//            // normalize W
//            vDSP.squareMagnitudes(W, result: &smPtr)
//            // use reciprocal square root
//            vForce.rsqrt(smPtr, result: &rsqrtPtr)
//            vDSP.multiply(W, by: rsqrtPtr, result: &W)
 
            break
            
        }
        
        // Phasor
        vDSP_zvmul(&Z, 1,
                   &W, 1,
                   &Z, 1,
                   vDSP_Length(numResonators),
                   1)
    }
    
    /// Process a frame of samples.
    /// Apply stabilization (norm correction) at the end
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            update(sample: frameData[sampleIndex])
        }
        stabilize() // this is overkill but necessary
    }
    
    /// Process a frame of samples.
    /// Apply stabilization (norm correction) at the end
    public func update(frame: [Float], thresholdDB: Float) {
        for sample in frame {
            update(sample: sample)
        }
        stabilize() // this is overkill but necessary
    }
    
    /// Apply norm correction to phasor.
    /// This can be done every few hundreds (?) of iterations
    func stabilize() {
        vDSP.squareMagnitudes(Z, result: &smPtr)
        // use reciprocal square root
        vForce.rsqrt(smPtr, result: &rsqrtPtr)
        vDSP.multiply(Z, by: rsqrtPtr, result: &Z)
    }
    
    public func reset() {
        rPtr.initialize(repeating: 0.0)
        rrPtr.initialize(repeating: 0.0)
        var one = Float(1.0)
        vDSP_vfill(&one, Z.realp, 1, vDSP_Length(numResonators))
        var zero = Float(0.0)
        vDSP_vfill(&zero, Z.imagp, 1, vDSP_Length(numResonators))
        powersPtr.initialize(repeating: 0.0)
        _ = wPtr.initialize(from: nwPtr)
    }
    
    public func setTimeConstant(_ tau: Float = 1.0, sampleRate: Float) {
        let sampleDuration =  1.0 / sampleRate
        sigma = Float(1.0) - exp(-sampleDuration / tau)
    }
    
    // Single pass all in one
    // apply threshold and reset
    static func fuseThresholdAndMerge(powersPtr: UnsafeMutableBufferPointer<Float>,
                                      dPtr: UnsafeMutableBufferPointer<Float>,
                                      naturalOmegasPtr: UnsafeMutableBufferPointer<Float>,
                                      threshold: Float) {
        guard let pBase = powersPtr.baseAddress,
              let dBase = dPtr.baseAddress,
              let nBase = naturalOmegasPtr.baseAddress else { return }
        
        let count = powersPtr.count
        let thresholdVec = SIMD8<Float>(repeating: threshold)
        
        var i = 0
        while i <= count - 8 {
            // 1. Load the three necessary pieces of data
            let p = UnsafeRawPointer(pBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            let d = UnsafeRawPointer(dBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            let n = UnsafeRawPointer(nBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            
            // 2. The Predicate: Which values are above threshold?
            let mask = p .>= thresholdVec
            
            // 3. The Ternary Select:
            // If power >= threshold, keep d.
            // Else, take naturalOmega.
            let result = n.replacing(with: d, where: mask)
            
            // 4. Store the result back into dPtr
            UnsafeMutableRawPointer(dBase.advanced(by: i))
                .storeBytes(of: result, as: SIMD8<Float>.self)
            
            i += 8
        }
        
        // Scalar Tail
        while i < count {
            dBase[i] = (pBase[i] >= threshold) ? dBase[i] : nBase[i]
            i += 1
        }
    }
    
    // Single pass all in one
    // apply threshold and reset
    static func fuseThresholdAndMerge(powersPtr: UnsafeMutableBufferPointer<Float>,
                                      D: DSPSplitComplex, // input: tracked omegas
                                      nW: DSPSplitComplex, // input: natural omegas
                                      W: DSPSplitComplex, // output
                                      threshold: Float) {
        guard let pBase = powersPtr.baseAddress else { return }
        let drBase = D.realp
        let diBase = D.imagp
        let nrBase = nW.realp
        let niBase = nW.imagp
        let wrBase = W.realp
        let wiBase = W.imagp
        
        let count = powersPtr.count
        let thresholdVec = SIMD8<Float>(repeating: threshold)
        
        var i = 0
        while i <= count - 8 {
            // 1. Load the three necessary pieces of data
            let p = UnsafeRawPointer(pBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            let dr = UnsafeRawPointer(drBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            let di = UnsafeRawPointer(diBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            let nr = UnsafeRawPointer(nrBase.advanced(by: i)).load(as: SIMD8<Float>.self)
            let ni = UnsafeRawPointer(niBase.advanced(by: i)).load(as: SIMD8<Float>.self)

            // 2. The Predicate: Which values are above threshold?
            let mask = p .>= thresholdVec
            
            // 3. The Ternary Select:
            // If power >= threshold, keep d.
            // Else, take naturalOmega.
            let rr = nr.replacing(with: dr, where: mask)
            let ri = ni.replacing(with: di, where: mask)

            // 4. Store the result into W
            UnsafeMutableRawPointer(wrBase.advanced(by: i))
                .storeBytes(of: rr, as: SIMD8<Float>.self)
            UnsafeMutableRawPointer(wiBase.advanced(by: i))
                .storeBytes(of: ri, as: SIMD8<Float>.self)

            i += 8
        }
        
        // Scalar Tail
        while i < count {
            wrBase[i] = (pBase[i] >= threshold) ? drBase[i] : nrBase[i]
            wiBase[i] = (pBase[i] >= threshold) ? diBase[i] : niBase[i]
            i += 1
        }
    }

}
