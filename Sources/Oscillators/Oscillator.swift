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

public class Oscillator : OscillatorProtocol {
    public private(set) var sampleDuration: Float
    public private(set) var frequency: Float
    
    public var amplitude: Float = 0.0
    
    public var waveform: [Float] {
        waveformPtr.map { $0 }
    }
    public private(set) var waveformPtr: UnsafeMutableBufferPointer<Float>
    internal var numSamplesInPeriod: Int {
        waveformPtr.count
    }
    internal var phaseIdx: Int = 0
    
    init(targetFrequency: Float, sampleDuration: Float) {
        self.sampleDuration = sampleDuration
        var numSamplesInPeriodLocal: Int
        (numSamplesInPeriodLocal, self.frequency) = Frequencies.closestFrequency(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        
        waveformPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInPeriodLocal)
        waveformPtr.initialize(repeating: 0)
        
        print("New Oscillator: target frequency: \(targetFrequency), num samples in period: \(numSamplesInPeriod) -> \(frequency)")
    }
    
    deinit {
        waveformPtr.baseAddress?.deinitialize(count: numSamplesInPeriod)
        waveformPtr.deallocate()
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
        vDSP.fill(&waveformPtr, with: 0.0)
    }
    
    public func setSquareWave() {
        let halfNumSamplesInPeriod = waveformPtr.count / 2
        vDSP.fill(&waveformPtr[..<halfNumSamplesInPeriod], with: 1.0)
        vDSP.fill(&waveformPtr[halfNumSamplesInPeriod...], with: -1.0)
    }
    
    public func setTriangleWave() {
        let quarterNumSamplesInPeriod = waveformPtr.count / 4
        let delta : Float = 1.0 / Float(quarterNumSamplesInPeriod)
        let threeQuartersNumSamplesInPeriod = 3 * quarterNumSamplesInPeriod
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &waveformPtr[..<quarterNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: 1.0, increment: -delta, result: &waveformPtr[quarterNumSamplesInPeriod..<threeQuartersNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: -1.0, increment: delta, result: &waveformPtr[threeQuartersNumSamplesInPeriod...])
    }
    
    public func setSawWave() {
        let halfNumSamplesInPeriod = waveformPtr.count / 2
        let delta : Float = 1.0 / Float(halfNumSamplesInPeriod)
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &waveformPtr[..<halfNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: -1.0, increment: delta, result: &waveformPtr[halfNumSamplesInPeriod...])
    }
    
    public func setSineWave() {
        let twoPiFrequency : Float = twoPi * frequency
        let delta : Float = twoPiFrequency * sampleDuration
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &waveformPtr)
        vForce.sin(waveformPtr, result: &waveformPtr)
    }
}
