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

final class ResonatorCppTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = ResonatorCpp(targetFrequency: 440.0,
                                     sampleDuration: AudioFixtures.sampleDuration44100,
                                     alpha: DynamicsFixtures.defaultAlpha)
        
        guard let resonator = resonator else { return XCTAssert(false) }

        XCTAssertEqual(resonator.alpha(), DynamicsFixtures.defaultAlpha)
    }
    
    func testSetAlpha() throws {
        var alpha: Float = 0.99
        let resonator = ResonatorCpp(targetFrequency: 440.0,
                                     sampleDuration: AudioFixtures.sampleDuration44100,
                                     alpha: alpha)
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        XCTAssertEqual(resonator.alpha(), alpha)
        XCTAssertEqual(resonator.omAlpha(), 1.0-alpha)

        alpha = 0.11
        resonator.setAlpha(alpha)
        XCTAssertEqual(resonator.omAlpha(), 1.0-alpha)
    }

    func testUpdateWithSample() throws {
        let resonator = ResonatorCpp(targetFrequency: 440.0,
                                     sampleDuration: AudioFixtures.sampleDuration44100,
                                     alpha: 1.0);
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        resonator.updateWithSample(value: 1.0)
        XCTAssertEqual(resonator.s(), resonator.waveformValue(0))
        XCTAssertEqual(resonator.c(), resonator.waveform2Value(0))
        resonator.updateWithSample(value: 0.0)
        XCTAssertEqual(resonator.s(), 0.0)
        XCTAssertEqual(resonator.c(), 0.0)
    }
    
    // Suggestion: test frequency tracking and phase?

    // This test is not really meaningful
//    func testUpdatePerf() throws {
//        let resonator = ResonatorCpp(targetFrequency: 10.0, sampleDuration: sampleDuration44100, alpha: defaultAlpha)
//        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
//
//        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
//        frame.initialize(repeating: 0.5, count: 1024)
//        measure {
//            resonator.update(frameData: frame, frameLength: 1024, sampleStride: 1)
//        }
//        frame.deallocate()
//    }
    
}
