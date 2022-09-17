/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import XCTest
@testable import Oscillators

fileprivate let epsilon : Float = 0.0001
fileprivate let twoPi = Float.pi * 2.0

final class OscillatorTests: XCTestCase {
    
    func testConstructor() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100)
        
        XCTAssertEqual(oscillator.sampleDuration, AudioFixtures.sampleDuration44100)
        
        XCTAssertNotNil(oscillator.waveformPtr)
//        print("waveformPtr base Address: \(String(describing: oscillator.waveformPtr.baseAddress)) = \(Int(bitPattern: oscillator.waveformPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: oscillator.waveformPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)

        XCTAssertEqual(oscillator.waveformPtr.count, oscillator.numSamplesInWaveform)

        XCTAssertEqual(oscillator.numSamplesInPeriod, 100)
        XCTAssertEqual(oscillator.frequency, 441.0)
        XCTAssertEqual(oscillator.amplitude, 0)
    }
    
    func testInitSquareWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100)
        oscillator.setWaveform(waveShape: .square)
        XCTAssertEqual(oscillator.waveformPtr[0], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)-1], -1.0, accuracy: epsilon)
    }
    
    func testInitTriangleWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100)
        oscillator.setWaveform(waveShape: .triangle)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)/4], 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(Int(oscillator.numSamplesInPeriod)/4)], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(Int(oscillator.numSamplesInPeriod)/4)], -1.0, accuracy: epsilon)
    }

    func testInitSawWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100)
        oscillator.setWaveform(waveShape: .saw)
        XCTAssertEqual(oscillator.waveformPtr[0], 0.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[Int(oscillator.numSamplesInPeriod)/4], 0.5 * 1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[2*(Int(oscillator.numSamplesInPeriod)/4)], -1.0, accuracy: epsilon)
        XCTAssertEqual(oscillator.waveformPtr[3*(Int(oscillator.numSamplesInPeriod)/4)], -0.5 * 1.0, accuracy: epsilon)
    }
    
    func testInitSineWave() throws {
        let oscillator = Oscillator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100)
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
