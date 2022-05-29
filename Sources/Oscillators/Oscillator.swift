import Foundation

public class Oscillator : OscillatorProtocol {
    public private(set) var sampleDuration: Float
    public private(set) var frequency: Float
    
    public var amplitude: Float
    internal var numSamplesInPeriod: Int

    init(targetFrequency: Float, sampleDuration: Float) {
        self.sampleDuration = sampleDuration
        let maxNumSamplesInPeriod = floor(1.0 / (sampleDuration * targetFrequency))
        self.frequency = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
        self.numSamplesInPeriod = Int(maxNumSamplesInPeriod)
        self.amplitude = 0.0
        
        print("New Oscillator: target frequency: \(targetFrequency), max num samples in period: \(maxNumSamplesInPeriod) -> \(frequency)")
    }
}
