import XCTest
@testable import Oscillators

fileprivate let epsilon : Float = 0.000001

final class FrequenciesTests: XCTestCase {
    
    func testClosestFrequency() throws {
        let samplingRate : Int = 44100
        let sampleDuration : Float = 1.0 / Float(samplingRate)
        var (numSamplesPerPeriod, frequency) = Frequencies.closestFrequency(targetFrequency: 440.0, sampleDuration: sampleDuration)
        XCTAssertEqual(frequency, 441.0, accuracy: epsilon)
        XCTAssertEqual(numSamplesPerPeriod, 100)
        (numSamplesPerPeriod, frequency) = Frequencies.closestFrequency(targetFrequency: 441.0, sampleDuration: sampleDuration)
        XCTAssertEqual(frequency, 441.0, accuracy: epsilon)
        XCTAssertEqual(numSamplesPerPeriod, 100)
    }

    func testIntegerFrequencies() throws {
        let samplingRate : Int = 44100
        let expectedFrequencies = [2, 3, 4, 5, 6, 7, 9, 10, 12, 14, 15, 18, 20, 21, 25, 28, 30, 35, 36, 42, 45, 49, 50, 60, 63, 70, 75, 84, 90, 98, 100, 105, 126, 140, 147, 300, 315, 350, 420, 441, 450, 490, 525, 588, 630, 700, 735, 882, 900, 980, 1050, 1225, 1260, 1470, 1575, 1764, 2100, 2205, 2450, 2940, 3150, 3675, 4410, 4900, 6300, 7350, 8820, 11025, 14700, 22050]
        let frequencies = Frequencies.integerFrequencies(samplingRate: samplingRate, minNumSamplesPerPeriod: 2, maxNumSamplesPerPeriod: samplingRate / 2, sorted: true)

        XCTAssertEqual(frequencies.count, 70)
        XCTAssertEqual(frequencies, expectedFrequencies)
    }
    
}
