import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0

final class OscillatorTests: XCTestCase {
    
    func testConstructor() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        
        XCTAssertEqual(oscillator.sampleDuration, sampleDuration44100)
        XCTAssertEqual(oscillator.numSamplesInPeriod, 100)
        XCTAssertEqual(oscillator.frequency, 441.0)
        XCTAssertEqual(oscillator.amplitude, 0)
    }
    
    
}
