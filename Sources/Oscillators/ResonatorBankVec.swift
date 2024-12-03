/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

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

/// A bank of independent resonators implemented as a single array, computations use the Accelerate framework with manual memory management (unsafe pointers)
public class ResonatorBankVec {
    public private(set) var sampleRate : Float

    public private(set) var numResonators : Int
    public private(set) var frequencies : [Float] // tuning in Hz
    public private(set) var amplitudes : [Float]

    public  let alphas : [Float] // can be tuned independently for each frequency
    private let omAlphas : [Float] // can be tuned independently for each frequency

    private var beta : Float
    private var omBeta : Float
    
    private var twoNumResonators : Int

    /// Accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    private var rPtr : UnsafeMutableBufferPointer<Float>
    /// Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    private var rrPtr : UnsafeMutableBufferPointer<Float>
    /// Vector of complex representation of accumulated resonance values
    private var R : DSPSplitComplex
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
    /// Squared magnitudes buffer (ntermediate calculations)
    private var smPtr : UnsafeMutableBufferPointer<Float>
    /// Reverse square root buffer (intermediate calculations)
    private var rsqrtPtr : UnsafeMutableBufferPointer<Float>

    public init(frequencies: [Float], sampleRate: Float, alphas: [Float]) {
        // check that frequencies and alphas have the same size
        assert(frequencies.count == alphas.count)
        
        self.sampleRate = sampleRate

        // initialize from passed frequencies
        self.frequencies = frequencies
        self.numResonators = frequencies.count
        amplitudes = [Float](repeating: 0, count: numResonators)

        // These must be 2 * numResonators size
        self.alphas = alphas + alphas
        self.omAlphas = vDSP.add(multiplication: (self.alphas, -1.0), 1.0)

        // TODO: fixed and hard-coded for now...
        self.beta = 0.001 * 44100.0 / sampleRate
        self.omBeta = 1.0 - beta
        
        twoNumResonators = 2 * numResonators
        
        // setup resonators
        rPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        rPtr.initialize(repeating: 0.0)
        rrPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        rrPtr.initialize(repeating: 0.0)
        R = DSPSplitComplex(realp: rrPtr.baseAddress!,
                            imagp: rrPtr.baseAddress! + numResonators)

        zPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        zPtr.initialize(repeating: 0.0)
        Z = DSPSplitComplex(realp: zPtr.baseAddress!,
                            imagp: zPtr.baseAddress! + numResonators)
        var one = Float(1.0)
        vDSP_vfill(&one, Z.realp, 1, vDSP_Length(numResonators))

        let twoPiOverSampleRate = twoPi / sampleRate
        wPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        wPtr.initialize(repeating: twoPiOverSampleRate)
        W = DSPSplitComplex(realp: wPtr.baseAddress!,
                            imagp: wPtr.baseAddress! + numResonators)
        
        // multiply 2 * PI / sampleRate by frequency for each resonator
        vDSP_vmul(W.realp, 1,
                  frequencies, 1,
                  W.realp, 1,
                  vDSP_Length(numResonators))
        vDSP_vmul(W.imagp, 1,
                  frequencies, 1,
                  W.imagp, 1,
                  vDSP_Length(numResonators))
        
        // then calculate cos and sin
        var count : Int32 = Int32(numResonators)
        vvcosf(W.realp, W.realp, &count)
        vvsinf(W.imagp, W.imagp, &count)
        
        alphasSample = UnsafeMutableBufferPointer<Float>.allocate(capacity: twoNumResonators)
        smPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        rsqrtPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
    }
    
    deinit {
        rPtr.deallocate()
        rrPtr.deallocate()
        zPtr.deallocate()
        wPtr.deallocate()
        alphasSample.deallocate()
        smPtr.deallocate()
        rsqrtPtr.deallocate()
    }
    
    /// Update all resonators in parallel
    func update(sample: Float) {
        var sampleVar = sample
        vDSP_vsmul(alphas, 1, &sampleVar, alphasSample.baseAddress!, 1, vDSP_Length(twoNumResonators));
        
        // resonator
        vDSP_vmma(rPtr.baseAddress!, 1,
                    omAlphas, 1,
                    zPtr.baseAddress!, 1,
                  alphasSample.baseAddress!, 1,
                    rPtr.baseAddress!, 1,
                    vDSP_Length(twoNumResonators))
        
        vDSP_vsmsma(rrPtr.baseAddress!, 1,
                    &omBeta,
                    rPtr.baseAddress!, 1,
                    &beta,
                    rrPtr.baseAddress!, 1,
                    vDSP_Length(twoNumResonators))

        // phasor
        vDSP_zvmul(&Z, 1,
                   &W, 1,
                   &Z, 1,
                   vDSP_Length(numResonators),
                   1)
     }
    
    /// Apply norm correction to phasor.
    /// This can be done every few hundreds (?) of iterations
    func stabilize() {
        vDSP.squareMagnitudes(Z, result: &smPtr)
        // use reciprocal square root
        vForce.rsqrt(smPtr, result: &rsqrtPtr)
        vDSP.multiply(Z, by: rsqrtPtr, result: &Z)
    }
    
    /// Process a frame of samples.
    /// Apply stabilization (norm correction) at the end
    /// Compute amplitudes (phasor magnitudes) at the end
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            update(sample: frameData[sampleIndex])
        }
        stabilize()
        
        // compute amplitudes
        vDSP.squareMagnitudes(R, result: &amplitudes)
        amplitudes = vForce.sqrt(amplitudes)
    }
}
