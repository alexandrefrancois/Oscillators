import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0

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
    
    func testUpdatePerf() throws {
        let resonator = Resonator(targetFrequency: 10.0, sampleDuration: sampleDuration44100, alpha: 0.001)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        measure {
            resonator.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        }
        frame.deallocate()
    }
    
    func testUpdateSafePerf() throws {
        let resonator = ResonatorSafe(targetFrequency: 10.0, sampleDuration: sampleDuration44100, alpha: 0.001)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        measure {
            resonator.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        }
        frame.deallocate()

    }
}
