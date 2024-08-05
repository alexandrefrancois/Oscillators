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
    public var alpha : Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0

    public private(set) var sampleRate : Float

    public private(set) var numResonators : Int
    public private(set) var frequencies : [Float] // tuning in Hz
    public private(set) var amplitudes : [Float]

    private var RcPtr : UnsafeMutableBufferPointer<Float>
    private var RsPtr: UnsafeMutableBufferPointer<Float>
    private var R : DSPSplitComplex
    private var ZcPtr : UnsafeMutableBufferPointer<Float>
    private var ZsPtr : UnsafeMutableBufferPointer<Float>
    private var Z : DSPSplitComplex
    private var WcPtr : UnsafeMutableBufferPointer<Float>
    private var WsPtr : UnsafeMutableBufferPointer<Float>
    private var W : DSPSplitComplex
    
    public init(frequencies: [Float], sampleRate: Float, alpha: Float) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.sampleRate = sampleRate

        // initialize from passed frequencies
        self.frequencies = frequencies
        self.numResonators = frequencies.count
        amplitudes = [Float](repeating: 0, count: numResonators)
        
        // setup resonators
        RcPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        RcPtr.initialize(repeating: 0.0)
        RsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        RsPtr.initialize(repeating: 0.0)
        R = DSPSplitComplex(realp: RcPtr.baseAddress!,
                            imagp: RsPtr.baseAddress!)

        ZcPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        ZcPtr.initialize(repeating: 1.0)
        ZsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        ZsPtr.initialize(repeating: 0.0)
        Z = DSPSplitComplex(realp: ZcPtr.baseAddress!,
                            imagp: ZsPtr.baseAddress!)

        let twoPiOverSampleRate = twoPi / sampleRate
        WcPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        WcPtr.initialize(repeating: twoPiOverSampleRate)
        WsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numResonators)
        WsPtr.initialize(repeating: twoPiOverSampleRate)
        W = DSPSplitComplex(realp: WcPtr.baseAddress!,
                            imagp: WsPtr.baseAddress!)
        
        // multiply 2 * PI / sampleRate by frequency for each resonator
        vDSP_vmul(WcPtr.baseAddress!, 1,
                  frequencies, 1,
                  WcPtr.baseAddress!, 1,
                  vDSP_Length(numResonators))
        vDSP_vmul(WsPtr.baseAddress!, 1,
                  frequencies, 1,
                  WsPtr.baseAddress!, 1,
                  vDSP_Length(numResonators))
        // then calculate cos and sin
        var count : Int32 = Int32(numResonators)
        vvcosf(WcPtr.baseAddress!, WcPtr.baseAddress!, &count)
        vvsinf(WsPtr.baseAddress!, WsPtr.baseAddress!, &count)
    }
    
    deinit {
        RcPtr.deallocate()
        RsPtr.deallocate()
        ZcPtr.deallocate()
        ZsPtr.deallocate()
        WcPtr.deallocate()
        WsPtr.deallocate()
    }
    
    func update(sample: Float) {
        var alphaSample = alpha * sample
        
        // resonator
        
//        vDSP_vsmsma(R.realp, 1,
//                    &omAlpha,
//                    Z.realp, 1,
//                    &alphaSample,
//                    R.realp, 1,
//                    vDSP_Length(numResonators))
//        vDSP_vsmsma(R.imagp, 1,
//                    &omAlpha,
//                    Z.imagp, 1,
//                    &alphaSample,
//                    R.imagp, 1,
//                    vDSP_Length(numResonators))
        
        vDSP_vsmsma(RcPtr.baseAddress!, 1,
                    &omAlpha,
                    ZcPtr.baseAddress!, 1,
                    &alphaSample,
                    RcPtr.baseAddress!, 1,
                    vDSP_Length(numResonators))
        vDSP_vsmsma(RsPtr.baseAddress!, 1,
                    &omAlpha,
                    ZsPtr.baseAddress!, 1,
                    &alphaSample,
                    RsPtr.baseAddress!, 1,
                    vDSP_Length(numResonators))

        // phasor
        vDSP_zvmul(&Z, 1,
                   &W, 1,
                   &Z, 1,
                   vDSP_Length(numResonators),
                   1)
     }
    
    func stabilize() {
        // use reciprocal square root
        vDSP.multiply(Z, by: vForce.rsqrt(vDSP.add(multiplication: (ZcPtr, ZcPtr), multiplication: (ZsPtr, ZsPtr))), result: &Z)
    }
    
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
