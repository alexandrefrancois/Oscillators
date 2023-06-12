/**
MIT License

Copyright (c) 2022-2023 Alexandre R. J. Francois

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

final class ResonatorTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = Resonator(targetFrequency: 440.0,
                                  sampleDuration: AudioFixtures.sampleDuration44100,
                                  alpha: DynamicsFixtures.defaultAlpha)
        
        XCTAssertEqual(resonator.alpha, DynamicsFixtures.defaultAlpha)
    }
    
    func testSetAlpha() throws {
        var alpha: Float = 0.99
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100, alpha: alpha)
        XCTAssertEqual(resonator.alpha, alpha)
        XCTAssertEqual(resonator.omAlpha, 1.0-alpha)

        alpha = 0.11
        resonator.alpha = alpha
        XCTAssertEqual(resonator.omAlpha, 1.0-alpha)
    }
    
    func testUpdateWithSample() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100, alpha: 1.0)
        resonator.updateWithSample(1.0)
        XCTAssertEqual(resonator.s, resonator.waveformPtr[0])
        XCTAssertEqual(resonator.c, resonator.waveform2Ptr[0])
        resonator.updateWithSample(0.0)
        XCTAssertEqual(resonator.s, 0.0)
        XCTAssertEqual(resonator.c, 0.0)
    }
  
    // Suggestion: test frequency tracking and phase?
}
