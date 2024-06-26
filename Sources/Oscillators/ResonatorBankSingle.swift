/**
MIT License

Copyright (c) 2022-2023 Alexandre R. J. Francois

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
public class ResonatorBankSingle {
    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0

    public private(set) var sampleDuration: Float

    public private(set) var numResonators: Int
    public private(set) var maxima: [Float]
    public private(set) var frequencies: [Float] // tuning in Hz
    
    public private(set) var sumSamplesPerPeriod: Int
    /// Number of samples per period for each oscillator
    public private(set) var samplesPerPeriodPtr: UnsafeMutableBufferPointer<Int>

    // Arrays of size sumSamplesPerPeriod
    
    /// Aplitude values for each phase for each oscillator
    public private(set) var allPhasesPtr: UnsafeMutableBufferPointer<Float>
    
    /// Waveform values for each phase index for each oscillator
    public private(set) var waveformsPtr: UnsafeMutableBufferPointer<Float>
    public private(set) var periodSampleCountsPtr: UnsafeMutableBufferPointer<Float>
    public private(set) var periodOffsetsPtr: UnsafeMutableBufferPointer<Float>
    public private(set) var phaseIndicesPtr: UnsafeMutableBufferPointer<Float>

    public private(set) var leftTermPtr: UnsafeMutableBufferPointer<Float>
    public private(set) var rightTermPtr: UnsafeMutableBufferPointer<Float>

    private var phaseWaveformPtr: UnsafeMutableBufferPointer<Float>
    private var phaseWaveformOffsetsPtr: UnsafeMutableBufferPointer<Float>

    
    // TODO: make initializers with different ways of specifying number of oscillators and frequencies
    public init(targetFrequencies: [Float], sampleDuration: Float, alpha: Float) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.sampleDuration = sampleDuration

        // initialize from passed frequencies
        self.numResonators = targetFrequencies.count
        self.frequencies = [Float](repeating: 0, count: numResonators)
        maxima = [Float](repeating: 0, count: numResonators)
        
//        print("Number of resonators: \(numResonators)")
        
        // setup an oscillator for each frequency
        samplesPerPeriodPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: numResonators)
        samplesPerPeriodPtr.initialize(repeating: 0)
        
        for index in 0..<numResonators {
            let targetFrequency = targetFrequencies[index]
            // pre-compute some sines and cosines for efficiency and to prevent drift
            let maxNumSamplesInPeriod = floor(1.0 / (sampleDuration * targetFrequency))
            samplesPerPeriodPtr[index] = Int(maxNumSamplesInPeriod)
            frequencies[index] = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
//            print("Target frequency: \(targetFrequency) | \(samplesPerPeriodPtr[index]) -> \(frequencies[index])")
            
        }
        sumSamplesPerPeriod = samplesPerPeriodPtr.reduce(0, +)
//        print("Total number of samples per period: \(sumSamplesPerPeriod)")

        allPhasesPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        allPhasesPtr.initialize(repeating: 0)

        waveformsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        periodSampleCountsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        periodOffsetsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        phaseIndicesPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        leftTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        rightTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        phaseWaveformPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        phaseWaveformOffsetsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)

        var nextOffset:Int = 0
        for index in 0..<numResonators {
            let waveformPtr = waveformsPtr.baseAddress! + nextOffset
            let numSamplesPerPeriod = samplesPerPeriodPtr[index]
            
            let frequency = frequencies[index]
            
            // prepare input values for waveform computation
            var zero : Float = 0
            let twoPiFrequency : Float = twoPi * frequency
            var delta : Float = twoPiFrequency * sampleDuration
            vDSP_vramp(&zero, &delta, waveformPtr, 1, vDSP_Length(numSamplesPerPeriod))
            
            // compute waveform values
            var count : Int32 = Int32(numSamplesPerPeriod)
            vvsinf(waveformPtr, waveformPtr, &count)
            
            // samples per period counts
            var numSamples : Float = Float(numSamplesPerPeriod)
            vDSP_vramp(&numSamples, &zero, periodSampleCountsPtr.baseAddress! + nextOffset, 1, vDSP_Length(numSamplesPerPeriod))
            
            // period offsets
            var offset : Float = Float(nextOffset)
            vDSP_vramp(&offset, &zero, periodOffsetsPtr.baseAddress! + nextOffset, 1, vDSP_Length(numSamplesPerPeriod))
            
            // phase indices
            var one : Float = 1
            vDSP_vramp(&zero, &one, phaseIndicesPtr.baseAddress! + nextOffset, 1, vDSP_Length(numSamplesPerPeriod))

            nextOffset += numSamplesPerPeriod
        }
    }
    
    deinit {
        allPhasesPtr.baseAddress?.deinitialize(count: sumSamplesPerPeriod)
        allPhasesPtr.deallocate()
        samplesPerPeriodPtr.deallocate()
        waveformsPtr.deallocate()
        
        periodSampleCountsPtr.deallocate()
        periodOffsetsPtr.deallocate()
        phaseIndicesPtr.deallocate()
        
        leftTermPtr.deallocate()
        rightTermPtr.deallocate()
        
        phaseWaveformPtr.deallocate()
        phaseWaveformOffsetsPtr.deallocate()
    }
    
    func update(sample: Float) {
        var alphaSample = alpha * sample
        var one : Float = 1

        leftTermPtr.initialize(repeating: 0)
        vDSP_vsmul(allPhasesPtr.baseAddress!, 1, &omAlpha, leftTermPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
        rightTermPtr.initialize(repeating: 0)
        vDSP_vadd(phaseIndicesPtr.baseAddress!, 1, periodOffsetsPtr.baseAddress!, 1, phaseWaveformOffsetsPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        var zero : Float = 0
        vDSP_vtabi(phaseWaveformOffsetsPtr.baseAddress!, 1, &one, &zero, waveformsPtr.baseAddress!, vDSP_Length(sumSamplesPerPeriod), phaseWaveformPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
        vDSP_vsmul(phaseWaveformPtr.baseAddress!, 1, &alphaSample, rightTermPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
        vDSP_vadd(leftTermPtr.baseAddress!, 1, rightTermPtr.baseAddress!, 1, allPhasesPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
        // all phases increment and modulus
        var numValues32 = Int32(sumSamplesPerPeriod)
        vDSP_vsadd(phaseIndicesPtr.baseAddress!, 1, &one, phaseIndicesPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        vvfmodf(phaseIndicesPtr.baseAddress!, phaseIndicesPtr.baseAddress!, periodSampleCountsPtr.baseAddress!, &numValues32)
    }
    
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            update(sample: frameData[sampleIndex])
        }
        // update maxima
        var countIndex = 0
        var length: vDSP_Length
        for index in stride(from: 0, to: numResonators, by: 1) {
            length = vDSP_Length(samplesPerPeriodPtr[index])
            var maxValue = Float(0.0)
            vDSP_maxv(allPhasesPtr.baseAddress! + countIndex,
                      1,
                      &maxValue,
                      length)
            countIndex += Int(length)
            maxima[index] = maxValue
        }
    }
}
