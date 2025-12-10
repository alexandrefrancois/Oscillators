/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

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
        let resonator = ResonatorCpp(frequency: 440.0,
                                     alpha: DynamicsFixtures.defaultAlpha,
                                     beta: DynamicsFixtures.defaultAlpha,
                                     gamma: DynamicsFixtures.defaultAlpha,
                                     sampleRate: AudioFixtures.defaultSampleRate)
        
        guard let resonator = resonator else { return XCTAssert(false) }

        XCTAssertEqual(resonator.alpha(), DynamicsFixtures.defaultAlpha)
        XCTAssertEqual(resonator.beta(), DynamicsFixtures.defaultAlpha)
    }
    
    func testSetAlpha() throws {
        var alpha: Float = 0.99
        let beta: Float = 0.88
        let gamma: Float = 0.99
        let resonator = ResonatorCpp(frequency: 440.0,
                                     alpha: alpha,
                                     beta: beta,
                                     gamma: gamma,
                                     sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        XCTAssertEqual(resonator.alpha(), alpha)
        XCTAssertEqual(resonator.omAlpha(), 1.0-alpha)
        XCTAssertEqual(resonator.beta(), beta)
        XCTAssertEqual(resonator.gamma(), gamma)

        alpha = 0.11
        resonator.setAlpha(alpha)
        XCTAssertEqual(resonator.omAlpha(), 1.0-alpha)
    }

    func testSetBeta() throws {
        let alpha: Float = 0.99
        var beta: Float = 0.88
        let gamma: Float = 0.99
        let resonator = ResonatorCpp(frequency: 440.0,
                                     alpha: alpha,
                                     beta: beta,
                                     gamma: gamma,
                                     sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        XCTAssertEqual(resonator.beta(), beta)
        XCTAssertEqual(resonator.omBeta(), 1.0-beta)
        XCTAssertEqual(resonator.alpha(), alpha)
        XCTAssertEqual(resonator.gamma(), gamma)

        beta = 0.33
        resonator.setBeta(beta)
        XCTAssertEqual(resonator.beta(), beta)
    }

    func testSetGamma() throws {
        let alpha: Float = 0.99
        let beta: Float = 0.88
        var gamma: Float = 0.99
        let resonator = ResonatorCpp(frequency: 440.0,
                                     alpha: alpha,
                                     beta: beta,
                                     gamma: gamma,
                                     sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        XCTAssertEqual(resonator.gamma(), gamma)
        XCTAssertEqual(resonator.omGamma(), 1.0-gamma)
        XCTAssertEqual(resonator.alpha(), alpha)
        XCTAssertEqual(resonator.beta(), beta)

        gamma = 0.33
        resonator.setGamma(gamma)
        XCTAssertEqual(resonator.gamma(), gamma)
    }

    func testUpdateWithSample() throws {
        let resonator = ResonatorCpp(frequency: 440.0,
                                     alpha: 1.0,
                                     beta: 1.0,
                                     gamma: 1.0,
                                     sampleRate: AudioFixtures.defaultSampleRate);
        guard let resonator = resonator else { return XCTAssert(false, "ResonatorCpp could not be instantiated") }
        resonator.updateWithSample(value: 1.0)
        resonator.updateWithSample(value: 0.0)
        XCTAssertEqual(resonator.s(), 0.0)
        XCTAssertEqual(resonator.c(), 0.0)
    }
    
    // Suggestion: test frequency tracking and phase?
}
