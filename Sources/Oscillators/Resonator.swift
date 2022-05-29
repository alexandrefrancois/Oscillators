import Foundation
import Accelerate

fileprivate let twoPi = Float.pi * 2.0
fileprivate let trackFrequencyThreshold = Float(0.001)

/**
    A single oscillator, computations use the Accelerate framework
 */
public class Resonator : Oscillator {
    
    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha : Float = 0.0
    public var trackedFrequency: Float = 0.0

    private var maxIdx: UInt = 0

    public private(set) var allPhasesPtr: UnsafeMutableBufferPointer<Float>?
    
    public private(set) var kernelPtr: UnsafeMutableBufferPointer<Float>?
    private var phaseIdx: Int = 0

    public private(set) var leftTermPtr: UnsafeMutableBufferPointer<Float>?
    public private(set) var rightTermPtr: UnsafeMutableBufferPointer<Float>?
    
    public init(targetFrequency: Float, sampleDuration: Float, alpha: Float = 0.0001) {
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        print("time constant: \(sampleDuration / alpha) s")
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)

        allPhasesPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInPeriod)
        allPhasesPtr!.initialize(repeating: 0)
        leftTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInPeriod)
        rightTermPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInPeriod)
        
        kernelPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInPeriod)
        kernelPtr!.initialize(repeating: 0)
        
       // prepare input values for kernel computation
        var zero : Float = 0
        let twoPiFrequency : Float = twoPi * frequency
        var delta : Float = twoPiFrequency * sampleDuration
        vDSP_vramp(&zero, &delta, kernelPtr!.baseAddress!, 1, vDSP_Length(numSamplesInPeriod))

        // compute kernel values
        var count : Int32 = Int32(numSamplesInPeriod)
        vvsinf(kernelPtr!.baseAddress!, kernelPtr!.baseAddress!, &count)
    }
    
    deinit {
        allPhasesPtr!.baseAddress?.deinitialize(count: numSamplesInPeriod)
        allPhasesPtr!.deallocate()
        leftTermPtr!.deallocate()
        rightTermPtr!.deallocate()
        kernelPtr!.deallocate()
    }
    
    func updateAllPhases(sample: Float) {
        var alphaSample : Float = alpha * sample

        leftTermPtr!.initialize(repeating: 0)
        vDSP_vsmul(allPhasesPtr!.baseAddress!, 1, &omAlpha, leftTermPtr!.baseAddress!, 1, vDSP_Length(numSamplesInPeriod))

        rightTermPtr!.initialize(repeating: 0)
        vDSP_vsmul(kernelPtr!.baseAddress! + phaseIdx, 1, &alphaSample, rightTermPtr!.baseAddress!, 1, vDSP_Length(numSamplesInPeriod - phaseIdx))
        vDSP_vsmul(kernelPtr!.baseAddress!, 1, &alphaSample, rightTermPtr!.baseAddress! + (numSamplesInPeriod - phaseIdx), 1, vDSP_Length(phaseIdx))
        
        vDSP_vadd(leftTermPtr!.baseAddress!, 1, rightTermPtr!.baseAddress!, 1, allPhasesPtr!.baseAddress!, 1, vDSP_Length(numSamplesInPeriod))
        phaseIdx = (phaseIdx + 1) % numSamplesInPeriod
        
    }
    
    public func update(sample: Float) {
        updateAllPhases(sample: sample)
        vDSP_maxv(allPhasesPtr!.baseAddress!, 1, &amplitude, vDSP_Length(numSamplesInPeriod))
   }
    
    public func update(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
        vDSP_maxv(allPhasesPtr!.baseAddress!, 1, &amplitude, vDSP_Length(numSamplesInPeriod))
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
        vDSP_maxv(allPhasesPtr!.baseAddress!, 1, &amplitude, vDSP_Length(numSamplesInPeriod))
    }
    
    public func updateAndTrack(sample: Float) {
        updateAllPhases(sample: sample)
        var idx: vDSP_Length = 0
        vDSP_maxvi(allPhasesPtr!.baseAddress!, 1, &amplitude, &idx, vDSP_Length(numSamplesInPeriod))
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: idx, numSamples: 1)
        } else {
            trackedFrequency = frequency
        }
    }
    
    public func updateAndTrack(samples: [Float]) {
        for sample in samples {
            updateAllPhases(sample: sample)
        }
        var idx: vDSP_Length = 0
        vDSP_maxvi(allPhasesPtr!.baseAddress!, 1, &amplitude, &idx, vDSP_Length(numSamplesInPeriod))
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: idx, numSamples: samples.count)
        } else {
            trackedFrequency = frequency
        }
    }

    public func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateAllPhases(sample: frameData[sampleIndex])
        }
        var idx: vDSP_Length = 0
        vDSP_maxvi(allPhasesPtr!.baseAddress!, 1, &amplitude, &idx, vDSP_Length(numSamplesInPeriod))
        if amplitude > trackFrequencyThreshold {
            updateTrackedFrequency(newMaxIdx: idx, numSamples: frameLength)
        } else {
            trackedFrequency = frequency
        }
    }
    
    func updateTrackedFrequency(newMaxIdx: UInt, numSamples: Int) {
        let numSamplesDrift = (Int(newMaxIdx) - Int(maxIdx)) % numSamplesInPeriod
        let periodCorrection = Float(numSamplesInPeriod) * Float(numSamplesDrift) / Float(numSamples)
        trackedFrequency = 1.0 / (sampleDuration * (Float(numSamplesInPeriod) - periodCorrection))
        maxIdx = newMaxIdx
    }

}
