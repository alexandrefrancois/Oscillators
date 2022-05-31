import Foundation
import Accelerate

fileprivate let twoPi = Float.pi * 2.0
fileprivate let trackFrequencyThreshold = Float(0.001)

/**
    A single oscillator, computations use the Accelerate framework with swift arrays
 */
public class ResonatorSafe : Oscillator, ResonatorProtocol {
    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0
    public var trackedFrequency: Float = 0.0

    private var maxIdx: UInt = 0

    public private(set) var allPhases = [Float]()
    public private(set) var kernel = [Float]()
    private var phaseIdx: Int = 0
    private var leftTerm = [Float]()
    private var rightTerm = [Float]()
    
    public init(targetFrequency: Float, sampleDuration: Float, alpha: Float) {
        self.alpha = alpha
        print("time constant: \(sampleDuration / alpha) s")
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)

        self.allPhases = [Float](repeating: 0, count: numSamplesInPeriod)
        leftTerm = [Float](repeating: 0, count: numSamplesInPeriod)
        rightTerm = [Float](repeating: 0, count: numSamplesInPeriod)
        
        kernel = [Float](repeating: 0, count: numSamplesInPeriod)
        initSineKernel()
    }
    
    public func initSineKernel() {
        let twoPiFrequency = twoPi * frequency
        let delta = twoPiFrequency * sampleDuration
        let angles = vDSP.ramp(withInitialValue: 0.0, increment: delta, count: numSamplesInPeriod)
        vForce.sin(angles, result: &kernel)
    }
    
    func updateAllPhases(sample: Float) {
        let alphaSample : Float = alpha * sample
        
        // print("Phase: \(phaseIdx) | \(alphaSampleAmplitude)")
        
        vDSP.clear(&leftTerm)
        vDSP.multiply(omAlpha, allPhases, result: &leftTerm)
        
//        print("Left term:")
//        for (index, element) in leftTerm.enumerated() {
//            print("\(index): \(element)")
//        }
        
        let complement = numSamplesInPeriod - phaseIdx

        vDSP.clear(&rightTerm)
        vDSP.multiply(alphaSample, kernel[..<complement], result: &rightTerm[phaseIdx...])
//        vDSP_vsmul(&(kernel[phaseIdx]), 1, &alphaSampleAmplitude, &rightTerm, 1, vDSP_Length(numSamplesInPeriod - phaseIdx))
        
        vDSP.multiply(alphaSample, kernel[complement...], result: &rightTerm[..<phaseIdx])
//        vDSP_vsmul(&kernel, 1, &alphaSampleAmplitude, &(rightTerm[numSamplesInPeriod - phaseIdx]), 1, vDSP_Length(phaseIdx))
        
//        print("Right term:")
//        for (index, element) in rightTerm.enumerated() {
//            print("\(index): \(element)")
//        }
        
        vDSP.add(leftTerm, rightTerm, result: &allPhases)
        
//        print("All phases:")
//        for (index, element) in allPhases.enumerated() {
//            print("\(index): \(element)")
//        }
        
        phaseIdx = (phaseIdx + 1) % numSamplesInPeriod
    }
    
    public func update(sample: Float) {
        // input amplitude is in [-1. 1]
        updateAllPhases(sample: sample)
   }
    
    public func update(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
    }
    
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
    }
    
    public func updateAndTrack(sample: Float) {
        // input amplitude is in [-1. 1]
        updateAllPhases(sample: sample)
        var maxIdx: UInt
        (maxIdx, self.amplitude) = vDSP.indexOfMaximum(allPhases)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: maxIdx, numSamples: 1)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
        var maxIdx: UInt
        (maxIdx, self.amplitude) = vDSP.indexOfMaximum(allPhases)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: maxIdx, numSamples: samples.count)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
        var maxIdx: UInt
        (maxIdx, self.amplitude) = vDSP.indexOfMaximum(allPhases)
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: maxIdx, numSamples: frameLength)
        } else {
            trackedFrequency = frequency
        }
    }

    func updateTrackedFrequency(newMaxIdx: UInt, numSamples: Int) {
        let numSamplesDrift = (Int(newMaxIdx) - Int(maxIdx)) % numSamplesInPeriod
        let periodCorrection = Float(numSamplesInPeriod) * Float(numSamplesDrift) / Float(numSamples)
        trackedFrequency = 1.0 / (sampleDuration * (Float(numSamplesInPeriod) + periodCorrection))
        maxIdx = newMaxIdx
    }
}
