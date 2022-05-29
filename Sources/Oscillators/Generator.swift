import Foundation
import Accelerate

fileprivate let twoPi = Float.pi * 2.0

public enum WaveShape {
    case square
    case triangle
    case saw
    case sine
    case silence
}
public class Generator : Oscillator, GeneratorProtocol {
    public private(set) var allPhases = [Float]()
    private var phaseIdx: Int = 0

    public init(targetFrequency: Float, sampleDuration: Float, waveShape: WaveShape) {
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        self.allPhases = [Float](repeating: 0, count: numSamplesInPeriod)
        setWaveform(waveShape: waveShape)
    }

    public func setWaveform(waveShape: WaveShape) {
        switch(waveShape) {
        case .square:
            setSquareWave()
        case .triangle:
            setTriangleWave()
        case .saw:
            setSawWave()
        case .sine:
            setSineWave()
        case .silence:
            setSilence()
        }
    }
    
    public func setSilence() {
        vDSP.fill(&allPhases, with: 0.0)
    }
    
    public func setSquareWave() {
        let halfNumSamplesInPeriod = numSamplesInPeriod / 2
        vDSP.fill(&allPhases[..<halfNumSamplesInPeriod], with: 1.0)
        vDSP.fill(&allPhases[halfNumSamplesInPeriod...], with: -1.0)
    }
    
    public func setTriangleWave() {
        let quarterNumSamplesInPeriod = numSamplesInPeriod / 4
        let delta : Float = 1.0 / Float(quarterNumSamplesInPeriod)
        let threeQuartersNumSamplesInPeriod = 3 * quarterNumSamplesInPeriod
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &allPhases[..<quarterNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: 1.0, increment: -delta, result: &allPhases[quarterNumSamplesInPeriod..<threeQuartersNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: -1.0, increment: delta, result: &allPhases[threeQuartersNumSamplesInPeriod...])
    }
    
    public func setSawWave() {
        let halfNumSamplesInPeriod = numSamplesInPeriod / 2
        let delta : Float = 1.0 / Float(halfNumSamplesInPeriod)
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &allPhases[..<halfNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: -1.0, increment: delta, result: &allPhases[halfNumSamplesInPeriod...])
    }
    
    public func setSineWave() {
        let twoPiFrequency = twoPi * frequency
        let delta = twoPiFrequency * sampleDuration
        let angles = vDSP.ramp(withInitialValue: 0.0, increment: delta, count: numSamplesInPeriod)
        vForce.sin(angles, result: &allPhases)
    }
    
    public func getNextSample() -> Float {
        let nextSample = allPhases[phaseIdx];
        phaseIdx = (phaseIdx + 1) % numSamplesInPeriod;
        return nextSample
    }
    
    public func getNextSamples(numSamples: Int) -> [Float] {
        var samples = [Float]()
        var samplesToGet = numSamples
        while samplesToGet > 0 {
            samples.append(allPhases[phaseIdx])
            samplesToGet -= 1
            phaseIdx = (phaseIdx + 1) % numSamplesInPeriod
        }
        return samples
    }
    
    public func getNextSamples(samples: inout [Float]) {
        var sampleIdx = 0
        while sampleIdx < samples.count {
            samples[sampleIdx] = allPhases[phaseIdx]
            sampleIdx += 1
            phaseIdx = (phaseIdx + 1) % numSamplesInPeriod
        }
    }
}
