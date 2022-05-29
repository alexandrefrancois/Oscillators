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
    
    func testInitSineWave() throws {
        let oscillator = OscillatorCpp(targetFrequency: 440.0, sampleDuration: sampleDuration44100);
        guard let oscillator = oscillator else { return XCTAssert(false, "OscillatorCpp could not be instantiated") }
        
        oscillator.setSineWave();
        
        // check waveform values
        let twoPiFrequency : Float = twoPi * oscillator.frequency();
        let delta : Float = twoPiFrequency * oscillator.sampleDuration();
        for i in 0..<oscillator.numSamplesInPeriod() {
            let alpha = Float(i) * delta
            XCTAssertEqual(oscillator.waveformValue(i), sin(alpha), accuracy: epsilon, "\(i): \(oscillator.waveformValue(i) - sin(alpha))")
        }
    }

}
