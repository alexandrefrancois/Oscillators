import Foundation
import Accelerate
import UIKit

fileprivate let twoPi = Float.pi * 2.0

/**
    A bank of independent oscillators, computations use the Accelerate framework
 */
public class ResonatorBank {
    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0

    public private(set) var sampleDuration: Float

    public private(set) var numOscillators: Int
    public private(set) var maxima: [Float]
    public private(set) var frequencies: [Float] // tuning in Hz
    
    public private(set) var sumSamplesPerPeriod: Int
    /// Number of samples per period for each oscillator
    public private(set) var samplesPerPeriodPtr: UnsafeMutableBufferPointer<Int>

    // Arrays of size sumSamplesPerPeriod
    
    /// Aplitude values for each phase for each oscillator
    public private(set) var allPhasesPtr: UnsafeMutableBufferPointer<Float>
    
    /// Kernel values for each phase index for each oscillator
    public private(set) var kernelsPtr: UnsafeMutableBufferPointer<Float>
    
    public private(set) var periodSampleCountsPtr: UnsafeMutableBufferPointer<Float>
    public private(set) var periodOffsetsPtr: UnsafeMutableBufferPointer<Float>
    public private(set) var phaseIndicesPtr: UnsafeMutableBufferPointer<Float>

    private var leftTermPtr: UnsafeMutableBufferPointer<Float>
    private var rightTermPtr: UnsafeMutableBufferPointer<Float>

    private var phaseKernelPtr: UnsafeMutableBufferPointer<Float>
    private var phaseKernelOffsetsPtr: UnsafeMutableBufferPointer<Float>

    
    // TODO: make initializers with different ways of specifying number of oscillators and frequencies
    public init(targetFrequencies: [Float], sampleDuration: Float, alpha: Float = 0.0001) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.sampleDuration = sampleDuration

        // initialize from passed frequencies
        self.numOscillators = targetFrequencies.count
        self.frequencies = [Float](repeating: 0, count: numOscillators)
        maxima = [Float](repeating: 0, count: numOscillators)
        
        print("Number of oscillators: \(numOscillators)")
        
        // setup an oscillator for each frequency
        samplesPerPeriodPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: numOscillators)
        samplesPerPeriodPtr.initialize(repeating: 0)
        
        for index in 0..<numOscillators {
            let targetFrequency = targetFrequencies[index]
            // pre-compute some cosines for efficiency and to prevent drift
            let maxNumSamplesInPeriod = floor(1.0 / (sampleDuration * targetFrequency))
            samplesPerPeriodPtr[index] = Int(maxNumSamplesInPeriod)
            frequencies[index] = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
            print("Target frequency: \(targetFrequency) | \(samplesPerPeriodPtr[index]) -> \(frequencies[index])")
            
        }
        sumSamplesPerPeriod = samplesPerPeriodPtr.reduce(0, +)
        print("Total number of samples per period: \(sumSamplesPerPeriod)")

        allPhasesPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        allPhasesPtr.initialize(repeating: 0)

        kernelsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        periodSampleCountsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        periodOffsetsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        phaseIndicesPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        leftTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        rightTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        phaseKernelPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)
        phaseKernelOffsetsPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: sumSamplesPerPeriod)

        var nextOffset:Int = 0
        for index in 0..<numOscillators {
            let kernelPtr = kernelsPtr.baseAddress! + nextOffset
            let numSamplesPerPeriod = samplesPerPeriodPtr[index]
            
            let frequency = frequencies[index]
            
            // prepare input values for kernel computation
            var zero : Float = 0
            let twoPiFrequency : Float = twoPi * frequency
            var delta : Float = twoPiFrequency * sampleDuration
            vDSP_vramp(&zero, &delta, kernelPtr, 1, vDSP_Length(numSamplesPerPeriod))
            
            // compute kernel values
            var count : Int32 = Int32(numSamplesPerPeriod)
            vvsinf(kernelPtr, kernelPtr, &count)
            
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
        kernelsPtr.deallocate()
        
        periodSampleCountsPtr.deallocate()
        periodOffsetsPtr.deallocate()
        phaseIndicesPtr.deallocate()
        
        leftTermPtr.deallocate()
        rightTermPtr.deallocate()
        
        phaseKernelPtr.deallocate()
        phaseKernelOffsetsPtr.deallocate()
    }
    
    func update(sample: Float) {
        
        var alphaSample = alpha * sample
        
        // this is o(n) in the size of the array
        // using individual read pointers could be more efficient?
        
        // all phases increment and modulus
        var numValues32 = Int32(sumSamplesPerPeriod)
        var one : Float = 1
        vDSP_vsadd(phaseIndicesPtr.baseAddress!, 1, &one, phaseIndicesPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        vvfmodf(phaseIndicesPtr.baseAddress!, phaseIndicesPtr.baseAddress!, periodSampleCountsPtr.baseAddress!, &numValues32)
                
        
//        // alphaCosines computation
//        // lookup alphaCosines by phase+offset
//        let phaseCosines = vDSP.linearInterpolate(lookupTable: cosines,
//                                            withOffsets: vDSP.add(phaseIndices, cosineOffsets))
//
//
//        vDSP.add(multiplication:(a: self.allPhases, b: omAlpha), multiplication: (c: phaseCosines, d: alphaSampleAmplitude), result: &self.allPhases)
//
//
        
        leftTermPtr.initialize(repeating: 0)
        vDSP_vsmul(allPhasesPtr.baseAddress!, 1, &omAlpha, leftTermPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
         
//            for (index, element) in leftTermPtr.enumerated() {
//                print("\(index): \(element)")
//            }

        rightTermPtr.initialize(repeating: 0)
        
        vDSP_vadd(phaseIndicesPtr.baseAddress!, 1, periodOffsetsPtr.baseAddress!, 1, phaseKernelOffsetsPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        var zero : Float = 0
        vDSP_vtabi(phaseKernelOffsetsPtr.baseAddress!, 1, &one, &zero, kernelsPtr.baseAddress!, vDSP_Length(sumSamplesPerPeriod), phaseKernelPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
        vDSP_vsmul(phaseKernelPtr.baseAddress!, 1, &alphaSample, rightTermPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
        vDSP_vadd(leftTermPtr.baseAddress!, 1, rightTermPtr.baseAddress!, 1, allPhasesPtr.baseAddress!, 1, vDSP_Length(sumSamplesPerPeriod))
        
//            for (index, element) in allPhasesPtr.enumerated() {
//                print("\(index): \(element)")
//            }

    }
    
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            update(sample: frameData[sampleIndex])
        }
        // update maxima
        var countIndex = 0
        var length: vDSP_Length
        for index in stride(from: 0, to: numOscillators, by: 1) {
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
