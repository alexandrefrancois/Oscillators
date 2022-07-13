import XCTest
@testable import OscillatorsCpp

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0

final class ResonatorCppTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = ResonatorCpp(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 0.0001)
        
        guard let resonator = resonator else { return XCTAssert(false) }

        XCTAssertEqual(resonator.alpha(), 0.0001)
    }
    
    func testUpdateAllPhases() throws {
        let resonator = ResonatorCpp(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 1.0);
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        resonator.updateAllPhases(sample: 1.0)
        for i in 0..<resonator.numSamplesInPeriod() {
            XCTAssertEqual(resonator.allPhasesValue(i), resonator.waveformValue(i))
        }
        resonator.updateAllPhases(sample: 0.0)
        for i in 0..<resonator.numSamplesInPeriod() {
            XCTAssertEqual(resonator.allPhasesValue(i), 0.0)
        }
    }
    
    func testUpdatePerf() throws {
        let resonator = ResonatorCpp(targetFrequency: 10.0, sampleDuration: sampleDuration44100, alpha: 0.001)
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }

        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        measure {
            resonator.update(frame: frame, frameLength: 1024, sampleStride: 1)
        }
        frame.deallocate()
    }
    
}
