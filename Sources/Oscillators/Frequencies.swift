import Foundation

/// A class to manipulate and compute frequencies in digital world
public struct Frequencies {
    
    public static func closestFrequency(targetFrequency: Float, sampleDuration: Float) -> (Int, Int, Float) {
        let maxNumSamplesInPeriod = (1.0 / (sampleDuration * targetFrequency)).rounded()
        let frequency = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
        return (Int(maxNumSamplesInPeriod), 1, frequency)
    }
    
//    static func closestFrequency(targetFrequency: Float, sampleDuration: Float, precision: Float = 0.1, maxTotalNbSamples: Int = 500) -> (Int, Int, Float) {
//        let samplingRate = 1/Float(sampleDuration)
////        let targetPeriodDuration = 1/targetFrequency
//        var nbPeriods = 1
//        var totalNbSamples = round(Float(samplingRate) / targetFrequency)
//        var frequency = 1 / (totalNbSamples * sampleDuration)
//        var error = abs((frequency - targetFrequency) / targetFrequency)
//        while (Int(totalNbSamples) < maxTotalNbSamples) && (error > precision) {
//            nbPeriods += 1
//            totalNbSamples = floor(Float(nbPeriods) * Float(samplingRate)  / targetFrequency)
//            frequency = Float(nbPeriods) / (totalNbSamples * sampleDuration)
//            error = abs((frequency - targetFrequency) / targetFrequency)
//        }
//        return (Int(totalNbSamples), nbPeriods, frequency)
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
}
