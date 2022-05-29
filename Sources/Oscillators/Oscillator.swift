/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

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

public enum WaveShape {
    case square
    case triangle
    case saw
    case sine
    case silence
}

/// Oscillator base class:
/// an oscillator is characterized by its frequency, amplitude and waveform
/// whose duration is an integer multiple of the sample duration
public class Oscillator : OscillatorProtocol {
    public private(set) var sampleDuration: Float
    public private(set) var frequency: Float
    
    public var amplitude: Float = 0.0
    
    public var waveform: [Float] {
        waveformPtr.map { $0 }
    }
    public private(set) var waveformPtr: UnsafeMutableBufferPointer<Float>
    internal var numSamplesInWaveform: Int {
        waveformPtr.count
    }
    internal var phaseIdx: Int = 0
    
    internal var numSamplesInPeriod: Float
    
    init(targetFrequency: Float, sampleDuration: Float) { //, accuracy: Float = Frequencies.defaultAccuracy, maxNumPeriods: Int = Frequencies.defaultMaxNumPeriods, maxTotalNumSamples: Int = Frequencies.defaultMaxTotalNumSamples) {
        self.sampleDuration = sampleDuration

        frequency = Frequencies.closestFrequency(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        numSamplesInPeriod = 1.0 / (frequency * sampleDuration)
                
        let numSamplesInWaveformLocal : Int = Int(numSamplesInPeriod)

        waveformPtr = UnsafeMutableBufferPointer<Float>.allocate(capacity: numSamplesInWaveformLocal)
        waveformPtr.initialize(repeating: 0)
        
//        print("New Oscillator: target frequency: \(targetFrequency), num samples in Period: \(numSamplesInPeriod) -> \(frequency)")
    }
    
    deinit {
        waveformPtr.baseAddress?.deinitialize(count: numSamplesInWaveform)
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
        // TODO: this is only correct if numPeriodsInWaveform == 1
        let halfNumSamplesInPeriod = waveformPtr.count / 2
        vDSP.fill(&waveformPtr[..<halfNumSamplesInPeriod], with: 1.0)
        vDSP.fill(&waveformPtr[halfNumSamplesInPeriod...], with: -1.0)
    }
    
    public func setTriangleWave() {
        // TODO: this is only correct if numPeriodsInWaveform == 1
        let quarterNumSamplesInPeriod = waveformPtr.count / 4
        let delta : Float = 1.0 / Float(quarterNumSamplesInPeriod)
        let threeQuartersNumSamplesInPeriod = 3 * quarterNumSamplesInPeriod
        vDSP.formRamp(withInitialValue: 0.0, increment: delta, result: &waveformPtr[..<quarterNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: 1.0, increment: -delta, result: &waveformPtr[quarterNumSamplesInPeriod..<threeQuartersNumSamplesInPeriod])
        vDSP.formRamp(withInitialValue: -1.0, increment: delta, result: &waveformPtr[threeQuartersNumSamplesInPeriod...])
    }
    
    public func setSawWave() {
        // TODO: this is only correct if numPeriodsInWaveform == 1
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
