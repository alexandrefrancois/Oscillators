import Foundation

public class Oscillator : OscillatorProtocol {
    public private(set) var sampleDuration: Float
    public private(set) var frequency: Float
    
    public var amplitude: Float
    internal var numSamplesInPeriod: Int

    init(targetFrequency: Float, sampleDuration: Float) {
        self.sampleDuration = sampleDuration
        (self.numSamplesInPeriod, self.frequency) = Frequencies.closestFrequency(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        self.amplitude = 0.0
        
        print("New Oscillator: target frequency: \(targetFrequency), num samples in period: \(numSamplesInPeriod) -> \(frequency)")
    }
}
