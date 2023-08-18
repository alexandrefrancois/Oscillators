/**
MIT License

Copyright (c) 2023 Alexandre R. J. Francois

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

public class SineLUT {
    
    static let shared = SineLUT()
    static let lutSize = 2048
    private static let cosOffset = lutSize / 4

    private(set) var lutPtr: UnsafeMutableBufferPointer<Float>
    
    private init() {
        // allocate LUT
        lutPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: Self.lutSize + 1)
        // Compute Sine values for LUT
        let delta : Float = twoPi / Float(Self.lutSize)
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &lutPtr)
        vForce.sin(lutPtr, result: &lutPtr)
        lutPtr[Self.lutSize] = lutPtr[0]
    }

    deinit {
        lutPtr.baseAddress?.deinitialize(count: Self.lutSize + 1)
        lutPtr.deallocate()
    }
    
    static func phaseIncrement(frequency: Float, samplingRate: Float) -> Float {
        Float(lutSize) * frequency / samplingRate
    }
    
    static func nextPhaseIndex(phaseIndex: Float, phaseIncrement: Float) -> Float {
        let phaseIdx = phaseIndex + phaseIncrement
        let idx = Int(phaseIdx)
        let a = phaseIdx - Float(idx)
        return Float(idx % lutSize) + a
    }
    
    static func cosPhaseIndex(phaseIdx: Float) -> Float {
        let cosIdx = phaseIdx + Float(Self.cosOffset)
        var idx = Int(cosIdx)
        let a = cosIdx - Float(idx)
        idx %= Self.lutSize
        return Float(idx) + a
    }
    
    func sin(phaseIdx: Float) -> Float {
        let idx = Int(phaseIdx)
        let s1 = lutPtr[idx]
        let s2 = lutPtr[idx+1]
        let a = phaseIdx - Float(idx)
        return s1 + (s2-s1) * a
    }
    
    func cos(phaseIdx: Float) -> Float {
        let cosIdx = phaseIdx + Float(Self.cosOffset)
        var idx = Int(cosIdx)
        let a = cosIdx - Float(idx)
        idx %= Self.lutSize
        let c1 = lutPtr[idx]
        let c2 = lutPtr[idx+1]
        return c1 + (c2-c1) * a
    }
    
    func sinCos(phaseIdx: Float) -> (Float, Float) {
        let idx = Int(phaseIdx)
        let s1 = lutPtr[idx]
        let s2 = lutPtr[idx+1]
        let a = phaseIdx - Float(idx)
        let s = s1 + (s2-s1) * a
        let cosIdx = (idx + Self.cosOffset) % Self.lutSize
        let c1 = lutPtr[cosIdx]
        let c2 = lutPtr[cosIdx+1]
        let c = c1 + (c2-c1) * a
        return (s,c)
    }
}
