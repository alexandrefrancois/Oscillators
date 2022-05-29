import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let windowRatio3 : Float = 1.0 / 3.0
fileprivate let sigmaRatio6 : Float = 1.0 / 6.0

final class ResonatorTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 0.0001)
        
        XCTAssertEqual(resonator.alpha, 0.0001)
        XCTAssertEqual(resonator.allPhases.count, resonator.numSamplesInPeriod)
        XCTAssertEqual(resonator.kernel.count, resonator.numSamplesInPeriod)
    }

    func testInitGaussianKernel() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 0.0001)
        resonator.initGaussianKernel(windowRatio: windowRatio3, sigmaRatio: sigmaRatio6)
        XCTAssertNotEqual(resonator.kernel[0], 0.0)
        let maxIndex = Int(Float(resonator.numSamplesInPeriod) * windowRatio3)
        XCTAssertNotEqual(resonator.kernel[0], 0.0)
        XCTAssertEqual(resonator.kernel[maxIndex/2], 1.0)
        XCTAssertEqual(resonator.kernel[maxIndex], 0.0)
    }
    
    func testUpdateAllPhases() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 0.0001)
        resonator.updateAllPhases(withAmplitude: 1.0, alpha: 1.0, omAlpha: 0.0)
        for i in 0..<resonator.numSamplesInPeriod {
            XCTAssertEqual(resonator.allPhases[i], resonator.kernel[i])
        }
        resonator.updateAllPhases(withAmplitude: 0.0, alpha: 0.5, omAlpha: 0.5)
        for i in 0..<resonator.numSamplesInPeriod {
            XCTAssertEqual(resonator.allPhases[i], 0.5 * resonator.kernel[i])
        }
    }
}
