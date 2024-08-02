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

fileprivate let epsilon : Float = 0.001
fileprivate let twoPi = Float.pi * 2.0

final class OscillatorTests: XCTestCase {
    
    func testConstructor() throws {
        let oscillator = Oscillator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate)
        
        XCTAssertEqual(oscillator.sampleRate, AudioFixtures.defaultSampleRate)
        XCTAssertEqual(oscillator.frequency, 440.0)
        XCTAssertEqual(oscillator.amplitude, 0)
    }
    
    func testPhasor() throws {
        let oscillator = Oscillator(frequency: 441.0, sampleRate: AudioFixtures.defaultSampleRate)
        let twoPiFrequency : Float = twoPi * oscillator.frequency
        let alpha : Float = twoPiFrequency // 600000 * twoPiFrequency / oscillator.sampleRate
        for i in 0..<441000{
//            let alpha = Float(i) * delta
//            XCTAssertEqual(oscillator.Wc, cos(alpha), accuracy: epsilon, "\(i): \(oscillator.Wc - cos(alpha))")
//            XCTAssertEqual(oscillator.Ws, sin(alpha), accuracy: epsilon, "\(i): \(oscillator.Ws - sin(alpha))")
            oscillator.incrementPhase()
            if i % 512 == 0 {
                oscillator.stabilize()
            }
        }
        
        // TODO: not sure where the error is larger - find a better test!
        XCTAssertEqual(oscillator.Wc, cos(alpha), accuracy: epsilon, "\(oscillator.Wc - cos(alpha))")
        XCTAssertEqual(oscillator.Ws, sin(alpha), accuracy: epsilon, "\(oscillator.Ws - sin(alpha))")
    }

}
