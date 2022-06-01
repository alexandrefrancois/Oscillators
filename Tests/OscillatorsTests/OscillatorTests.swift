import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let epsilon : Float = 0.000001

final class OscillatorTests: XCTestCase {
    
    func testConstructor() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        
        XCTAssertEqual(oscillator.sampleDuration, sampleDuration44100)
        
        XCTAssertNotNil(oscillator.waveformPtr)
        print("kernelsPtr base Address: \(String(describing: oscillator.waveformPtr.baseAddress)) = \(Int(bitPattern: oscillator.waveformPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: oscillator.waveformPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)

        XCTAssertEqual(oscillator.waveformPtr.count, oscillator.numSamplesInPeriod)

        XCTAssertEqual(oscillator.numSamplesInPeriod, 100)
        XCTAssertEqual(oscillator.frequency, 441.0)
        XCTAssertEqual(oscillator.amplitude, 0)
    }
    
    func testInitSquareWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .square)
        XCTAssertEqual(oscillator.waveformPtr[0], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[oscillator.numSamplesInPeriod-1], -1.0, accuracy: epsilon)
    }
    
    func testInitTriangleWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .triangle)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[oscillator.numSamplesInPeriod/4], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(oscillator.numSamplesInPeriod/4)], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(oscillator.numSamplesInPeriod/4)], -1.0, accuracy: epsilon)
    }

    func testInitSawWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .saw)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[oscillator.numSamplesInPeriod/4], 0.5 * 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(oscillator.numSamplesInPeriod/4)], -1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(oscillator.numSamplesInPeriod/4)], -0.5 * 1.0, accuracy: epsilon)
    }
    
    func testInitSineWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .sine)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0)
        XCTAssertEqual(oscillator.waveformPtr[oscillator.numSamplesInPeriod/4], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(oscillator.numSamplesInPeriod/4)], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(oscillator.numSamplesInPeriod/4)], -1.0, accuracy: epsilon)
    }

}
