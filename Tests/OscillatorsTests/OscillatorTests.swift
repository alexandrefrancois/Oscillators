import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let epsilon : Float = 0.0001
fileprivate let twoPi = Float.pi * 2.0

final class OscillatorTests: XCTestCase {
    
    func testConstructor() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        
        XCTAssertEqual(oscillator.sampleDuration, sampleDuration44100)
        
        XCTAssertNotNil(oscillator.waveformPtr)
        print("waveformPtr base Address: \(String(describing: oscillator.waveformPtr.baseAddress)) = \(Int(bitPattern: oscillator.waveformPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: oscillator.waveformPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)

        XCTAssertEqual(oscillator.waveformPtr.count, oscillator.numSamplesInWaveform)

        XCTAssertEqual(oscillator.numSamplesInPeriod, 100)
        XCTAssertEqual(oscillator.frequency, 441.0)
        XCTAssertEqual(oscillator.amplitude, 0)
    }
    
    func testInitSquareWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .square)
        XCTAssertEqual(oscillator.waveformPtr[0], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)-1], -1.0, accuracy: epsilon)
    }
    
    func testInitTriangleWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .triangle)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)/4], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(Int(oscillator.numSamplesInPeriod)/4)], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(Int(oscillator.numSamplesInPeriod)/4)], -1.0, accuracy: epsilon)
    }

    func testInitSawWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .saw)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)/4], 0.5 * 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(Int(oscillator.numSamplesInPeriod)/4)], -1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(Int(oscillator.numSamplesInPeriod)/4)], -0.5 * 1.0, accuracy: epsilon)
    }
    
    func testInitSineWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        oscillator.setWaveform(waveShape: .sine)
        // check waveform values
        let twoPiFrequency : Float = twoPi * oscillator.frequency
        let delta : Float = twoPiFrequency * oscillator.sampleDuration
        for i in 0..<oscillator.numSamplesInWaveform{
//            print("\(i): \(oscillator.waveformPtr[i])")
            let alpha = Float(i) * delta
            XCTAssertEqual(oscillator.waveformPtr[i], sin(alpha), accuracy: epsilon, "\(i): \(oscillator.waveformPtr[i] - sin(alpha))")
        }
    }

}
