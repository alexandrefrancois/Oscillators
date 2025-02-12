/**
MIT License

Copyright (c) 2022-2025 Alexandre R. J. Francois

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

final class PhasorTests: XCTestCase {
    
    func testConstructor() throws {
        let frequency = Float(440.0)
        let sampleRate = AudioFixtures.defaultSampleRate
        
        let phasor = Phasor(frequency: frequency, sampleRate: sampleRate)
        
        XCTAssertEqual(phasor.sampleRate, AudioFixtures.defaultSampleRate)
        XCTAssertEqual(phasor.frequency, frequency)
        XCTAssertEqual(phasor.sampleRate, sampleRate)
    }
    
    func testUpdateMultiplier() throws {
        let frequency = Float(440.0)
        let sampleRate = AudioFixtures.defaultSampleRate

        let phasor = Phasor(frequency: frequency, sampleRate: sampleRate)

        // initial values
        var omega = twoPi * frequency / sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))
        
        // change frequency
        phasor.frequency = Float(880.0)
        omega = twoPi * phasor.frequency / phasor.sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))

        // change sampleRate
        phasor.sampleRate = Float(48000.0)
        omega = twoPi * phasor.frequency / phasor.sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))

    }
    
    func testPhasor() throws {
        let phasor = Phasor(frequency: 441.0, sampleRate: AudioFixtures.defaultSampleRate)
        let twoPiFrequency : Float = twoPi * phasor.frequency
        
        // This checks that the phasor's frequency does not drift after a number of iterations
        // that corresponds to a multiple of the number of samples in the oscillator's period
        let alpha : Float = twoPiFrequency
        for i in 0..<4410000 {
            phasor.incrementPhase()
            if i % 1024 == 0 {
                phasor.stabilize()
            }
        }
        XCTAssertEqual(phasor.Zc, cos(alpha), accuracy: epsilon, "\(phasor.Zc - cos(alpha))")
        XCTAssertEqual(phasor.Zs, sin(alpha), accuracy: epsilon, "\(phasor.Zs - sin(alpha))")
    }

}
