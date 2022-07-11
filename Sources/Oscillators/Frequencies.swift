import Foundation

/// Speed of sound at room temperature, in m/s
fileprivate let speedOfSound: Float = 346.0

/// A class to manipulate and compute frequencies in digital world
public struct Frequencies {
    
//    static let defaultAccuracy: Float = 0.000001
//    static let defaultMaxNumPeriods: Int = 1
//    static let defaultMaxTotalNumSamples: Int = 4096
    
    public static func closestFrequency(targetFrequency: Float, sampleDuration: Float) -> (Int, Int, Float) {
        let maxNumSamplesInPeriod = (1.0 / (sampleDuration * targetFrequency)).rounded()
        let frequency = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
        return (Int(maxNumSamplesInPeriod), 1, frequency)
    }
    
//    static func closestFrequency(targetFrequency: Float, sampleDuration: Float, accuracy: Float = defaultAccuracy, maxNumPeriods: Int = Frequencies.defaultMaxNumPeriods, maxTotalNumSamples: Int = defaultMaxTotalNumSamples) -> (Int, Int, Float) {
//        let samplingRate = 1/Float(sampleDuration)
//        var numPeriods = 1
//        var totalNumSamples = round(Float(samplingRate) / targetFrequency)
//        var frequency = 1 / (totalNumSamples * sampleDuration)
//        var error = abs((frequency - targetFrequency) / targetFrequency)
//        while ((numPeriods < maxNumPeriods) && Int(totalNumSamples) < maxTotalNumSamples) && (error > accuracy) {
//            numPeriods += 1
//            totalNumSamples = floor(Float(numPeriods) * Float(samplingRate)  / targetFrequency)
//            frequency = Float(numPeriods) / (totalNumSamples * sampleDuration)
//            error = abs((frequency - targetFrequency) / targetFrequency)
//        }
//        return (Int(totalNumSamples), numPeriods, frequency)
//    }
    
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
    
    /// Compute the Doppler velocity from an observed and source frequency.
    /// - parameter observedFrequency: the frequency measured by the observer
    /// - parameter referenceFrequency: the frequency of the sound emitted by the source
    /// - returns: the relative velocity of the source to the receiver (positive when they are getting closer)
    public static func dopplerVelocity(observedFrequency: Float, referenceFrequency: Float) -> Float {
        guard referenceFrequency > 0 else { return 0 }
        return speedOfSound * (observedFrequency - referenceFrequency) / referenceFrequency
    }
}
