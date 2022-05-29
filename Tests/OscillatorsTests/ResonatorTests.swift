import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let windowRatio3 : Float = 1.0 / 3.0
fileprivate let sigmaRatio6 : Float = 1.0 / 6.0

final class ResonatorTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 0.0001)
        
        XCTAssertEqual(resonator.alpha, 0.0001)
        XCTAssertNotNil(resonator.allPhasesPtr)
        XCTAssertNotNil(resonator.kernelPtr)
        XCTAssertNotNil(resonator.leftTermPtr)
        XCTAssertNotNil(resonator.rightTermPtr)
    }
    
    func testUpdateAllPhases() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 1.0)
        resonator.updateAllPhases(sample: 1.0)
        for i in 0..<resonator.numSamplesInPeriod {
            XCTAssertEqual(resonator.allPhasesPtr![i], resonator.kernelPtr![i])
        }
        resonator.updateAllPhases(sample: 0.0)
        for i in 0..<resonator.numSamplesInPeriod {
            XCTAssertEqual(resonator.allPhasesPtr![i], 0.0)
        }
    }
}
