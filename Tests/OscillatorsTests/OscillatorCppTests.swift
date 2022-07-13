import XCTest
@testable import OscillatorsCpp

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let epsilon : Float = 0.0001
fileprivate let twoPi = Float.pi * 2.0

final class OscillatorCppTests: XCTestCase {
    
    func testConstructor() throws {
        let oscillator = OscillatorCpp(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
        guard let oscillator = oscillator else { return XCTAssert(false, "OscillatorCpp could not be instantiated") }
        
        XCTAssertEqual(oscillator.sampleDuration(), sampleDuration44100)
        XCTAssertEqual(oscillator.numSamplesInPeriod(), 100)
        XCTAssertEqual(oscillator.frequency(), 441.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.amplitude(), 0.0, accuracy: epsilon)
        
        let size:Int = Int(oscillator.numSamplesInPeriod())
        var waveform = [Float](repeating: 1.0, count: size)
        oscillator.copyWaveform(&waveform, size: Int32(size))
        XCTAssertEqual(waveform[size/2], 0.0, accuracy: epsilon)
    }
    
//    func testInitSquareWave() throws {
//        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
//        oscillator.setWaveform(waveShape: .square)
//        XCTAssertEqual(oscillator.waveformPtr[0], 1.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)-1], -1.0, accuracy: epsilon)
//    }
//
//    func testInitTriangleWave() throws {
//        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
//        oscillator.setWaveform(waveShape: .triangle)
//        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)/4], 1.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[2*(Int(oscillator.numSamplesInPeriod)/4)], 0.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[3*(Int(oscillator.numSamplesInPeriod)/4)], -1.0, accuracy: epsilon)
//    }
//
//    func testInitSawWave() throws {
//        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: sampleDuration44100)
//        oscillator.setWaveform(waveShape: .saw)
//        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)/4], 0.5 * 1.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[2*(Int(oscillator.numSamplesInPeriod)/4)], -1.0, accuracy: epsilon)
//        XCTAssertEqual(oscillator.waveformPtr[3*(Int(oscillator.numSamplesInPeriod)/4)], -0.5 * 1.0, accuracy: epsilon)
//    }

    func testInitSineWave() throws {
        let oscillator = OscillatorCpp(targetFrequency: 440.0, sampleDuration: sampleDuration44100);
        guard let oscillator = oscillator else { return XCTAssert(false, "OscillatorCpp could not be instantiated") }
        
        oscillator.setSineWave();
        
        // check waveform values
        let twoPiFrequency : Float = twoPi * oscillator.frequency();
        let delta : Float = twoPiFrequency * oscillator.sampleDuration();
        for i in 0..<oscillator.numSamplesInPeriod() {
//            print("\(i): \(oscillator.waveformPtr[i])")
            let alpha = Float(i) * delta
            XCTAssertEqual(oscillator.waveformValue(i), sin(alpha), accuracy: epsilon, "\(i): \(oscillator.waveformValue(i) - sin(alpha))")
        }
    }

}
