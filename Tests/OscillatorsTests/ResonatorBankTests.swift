import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let targetFrequencies : [Float] = [10.0, 100.0, 440.0, 880.0, 1600.0]

final class ResonatorBankTests: XCTestCase {
    func testConstructor() throws {
        let resonatorBank = ResonatorBank(targetFrequencies: targetFrequencies, sampleDuration: sampleDuration44100, alpha: 0.0001)
        
        XCTAssertEqual(resonatorBank.alpha, 0.0001)
        XCTAssertNotNil(resonatorBank.allPhasesPtr)
        XCTAssertNotNil(resonatorBank.kernelsPtr)
        XCTAssertNotNil(resonatorBank.leftTermPtr)
        XCTAssertNotNil(resonatorBank.rightTermPtr)
    }
    
    func testUpdateAllPhases() throws {
        let resonatorBank = ResonatorBank(targetFrequencies: targetFrequencies, sampleDuration: sampleDuration44100, alpha: 1.0)
        resonatorBank.update(sample: 1.0)
        for i in 0..<resonatorBank.sumSamplesPerPeriod {
            XCTAssertEqual(resonatorBank.allPhasesPtr[i], resonatorBank.kernelsPtr[i])
        }
        resonatorBank.update(sample: 0.0)
        for i in 0..<resonatorBank.sumSamplesPerPeriod {
            XCTAssertEqual(resonatorBank.allPhasesPtr[i], 0.0)
        }
    }
    
    func testUpdatePerf() throws {
        let resonatorBank = ResonatorBank(targetFrequencies: targetFrequencies, sampleDuration: sampleDuration44100, alpha: 1.0)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        measure {
            resonatorBank.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        }
        frame.deallocate()
    }

}
