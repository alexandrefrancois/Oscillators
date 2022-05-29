import Foundation

/// A class to manipulate and compute frequencies in digital world
public struct Frequencies {
    
    public static func closestFrequency(targetFrequency: Float, sampleDuration: Float) -> (Int, Float) {
        let maxNumSamplesInPeriod = (1.0 / (sampleDuration * targetFrequency)).rounded()
        let frequency = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
        return (Int(maxNumSamplesInPeriod), frequency)
    }
    
    public static func integerFrequencies(samplingRate: Int, minNumSamplesPerPeriod: Int, maxNumSamplesPerPeriod: Int, sorted: Bool = true) -> [Int] {
        var frequencies = [Int]()
        let from = max(2, minNumSamplesPerPeriod)
        let to = Int(sqrt(Float(min(samplingRate/2, maxNumSamplesPerPeriod))))
        for i in from...to {
            if samplingRate % i == 0 {
                frequencies.append(i)
                frequencies.append(samplingRate / i)
            }
        }
        return sorted ? frequencies.sorted() : frequencies
    }
}
