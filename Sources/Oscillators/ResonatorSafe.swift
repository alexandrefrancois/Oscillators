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
    
    public var timeConstant : Float {
        sampleDuration / alpha
    }

    public var trackedFrequency: Float = 0.0
    private var maxIdx: UInt = 0

    public private(set) var allPhases = [Float]()
    private var leftTerm = [Float]()
    private var rightTerm = [Float]()
    
    public init(targetFrequency: Float, sampleDuration: Float, alpha: Float) {
        self.alpha = alpha
        print("time constant: \(sampleDuration / alpha) s")
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)

        self.allPhases = [Float](repeating: 0, count: numSamplesInWaveform)
        leftTerm = [Float](repeating: 0, count: numSamplesInWaveform)
        rightTerm = [Float](repeating: 0, count: numSamplesInWaveform)
        
        setWaveform(waveShape: .sine)
    }
        
    func updateAllPhases(sample: Float) {
        let alphaSample : Float = alpha * sample
        
        // print("Phase: \(phaseIdx) | \(alphaSampleAmplitude)")
        
        vDSP.multiply(omAlpha, allPhases, result: &leftTerm)
        
//        print("Left term:")
//        for (index, element) in leftTerm.enumerated() {
//            print("\(index): \(element)")
//        }
        
        let complement = numSamplesInWaveform - phaseIdx
        vDSP.multiply(alphaSample, waveformPtr[..<complement], result: &rightTerm[phaseIdx...])
        vDSP.multiply(alphaSample, waveformPtr[complement...], result: &rightTerm[..<phaseIdx])
        
//        print("Right term:")
//        for (index, element) in rightTerm.enumerated() {
//            print("\(index): \(element)")
//        }
        
        vDSP.add(leftTerm, rightTerm, result: &allPhases)
        
//        print("All phases:")
//        for (index, element) in allPhases.enumerated() {
//            print("\(index): \(element)")
//        }
        
        phaseIdx = (phaseIdx + 1) % numSamplesInWaveform
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
        let numSamplesDrift = (Int(newMaxIdx) - Int(maxIdx)) % numSamplesInWaveform
        let periodCorrection = Float(numSamplesInWaveform) * Float(numSamplesDrift) / Float(numSamples)
        trackedFrequency = 1.0 / (sampleDuration * (Float(numSamplesInWaveform) + periodCorrection))
        maxIdx = newMaxIdx
    }
}
