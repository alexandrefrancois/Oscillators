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
fileprivate let twoPi = Float.pi * Float(2.0)

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
        var omega = -twoPi * frequency / sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))
        
        // change frequency
        phasor.frequency = Float(880.0)
        omega = -twoPi * phasor.frequency / phasor.sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))

        // change sampleRate
        phasor.sampleRate = Float(48000.0)
        omega = -twoPi * phasor.frequency / phasor.sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))

    }

    func testSettingOmegaStillUpdatesMultiplier() throws {
        let phasor = Phasor(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate)
        let omega = Float(-0.5)

        phasor.omega = omega

        XCTAssertEqual(phasor.Wc, cos(omega), accuracy: 1e-6)
        XCTAssertEqual(phasor.Ws, sin(omega), accuracy: 1e-6)
        XCTAssertEqual(phasor.Wcps, cos(omega) + sin(omega), accuracy: 1e-6)
    }

    func testSettingMultiplierAllowsOmegaReadout() throws {
        let phasor = Phasor(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate)
        let omega = Float(-0.25)

        phasor.setMultiplier(c: cos(omega), s: sin(omega))

        XCTAssertEqual(phasor.omega, omega, accuracy: 1e-6)
    }

    func testSettingMultiplierAllowsFrequencyReadout() throws {
        let sampleRate = AudioFixtures.defaultSampleRate
        let phasor = Phasor(frequency: 440.0, sampleRate: sampleRate)
        let frequency = Float(880.0)
        let omega = -twoPi * frequency / sampleRate

        phasor.setMultiplier(c: cos(omega), s: sin(omega))

        XCTAssertEqual(phasor.frequency, frequency, accuracy: 1e-4)
    }

    func testSettingMultiplierDoesNotChangeMultiplierBeforeReadout() throws {
        let phasor = Phasor(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate)
        let omega = Float(-0.125)
        let c = cos(omega)
        let s = sin(omega)

        phasor.setMultiplier(c: c, s: s)

        XCTAssertEqual(phasor.Wc, c, accuracy: 1e-6)
        XCTAssertEqual(phasor.Ws, s, accuracy: 1e-6)
        XCTAssertEqual(phasor.Wcps, c + s, accuracy: 1e-6)
    }
    
    func testPhasor() throws {
        let frequencies: [Float] = [10.0, 27.5, 55.0, 110.0, 220.0, 440.0, 880.0, 1_000.0, 1_760.0, 2_500.0, 4_410.0, 8_000.0]
        let sampleRate = AudioFixtures.defaultSampleRate
        let sampleCount = Int(sampleRate)
        let maximumFrequencyError: Float = 0.01
        
        for frequency in frequencies {
            let phasor = Phasor(frequency: frequency, sampleRate: sampleRate)
//            var stabilizeCount: Int = 0
            
            for i in 0..<sampleCount {
                phasor.incrementPhase()
                if i % 1024 == 0 {
                    phasor.stabilize()
                }
//                stabilizeCount = max(stabilizeCount, phasor.stabilizeIfNeeded())
            }
            
            let expectedPhase = -Double(twoPi) * Double(frequency) * Double(sampleCount) / Double(sampleRate)
            let expectedZc = Float(cos(expectedPhase))
            let expectedZs = Float(sin(expectedPhase))
            let dot = phasor.Zc * expectedZc + phasor.Zs * expectedZs
            let cross = expectedZc * phasor.Zs - expectedZs * phasor.Zc
            let phaseError = Float(abs(atan2(Double(cross), Double(dot))))
            let frequencyError = phaseError * sampleRate / (twoPi * Float(sampleCount))
            
            XCTAssertEqual(phasor.magnitude, 1.0, accuracy: epsilon, "frequency: \(frequency), magnitude error: \(phasor.magnitude - 1.0)")
            XCTAssertLessThanOrEqual(frequencyError, maximumFrequencyError, "frequency: \(frequency), frequency error: \(frequencyError) Hz")
            
//            print(stabilizeCount, phasor.magnitude)
        }
    }

}
