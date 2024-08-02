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

fileprivate let epsilon : Float = 0.000001

final class GeneratorTests: XCTestCase {
        
    func testGetNextSample() throws {
        let amplitude : Float = 0.5
        let generator = Generator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, amplitude: amplitude)
        let nextSample = generator.getNextSample()
//        XCTAssertEqual(nextSample, amplitude, accuracy: epsilon)
    }
    
    func testGetNextSamples1() throws {
        let amplitude : Float = 0.5
        let generator = Generator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, amplitude: amplitude)
        let numSamples = 3000
        let samples = generator.getNextSamples(numSamples: numSamples)
        XCTAssertEqual(samples.count, numSamples)
//        XCTAssertEqual(samples[0], amplitude, accuracy: epsilon)
//        XCTAssertEqual(samples[Int(generator.numSamplesInPeriod) / 2 - 1], amplitude, accuracy: epsilon)
//        XCTAssertEqual(samples[Int(generator.numSamplesInPeriod) / 2 + 1], -amplitude, accuracy: epsilon)
//        XCTAssertEqual(samples[Int(generator.numSamplesInPeriod)], amplitude, accuracy: epsilon)
    }

    func testGetNextSamples2() throws {
        let amplitude : Float = 0.5
        let generator = Generator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, amplitude: amplitude)
        let numSamples = 3000
        var samples = [Float](repeating: 0.0, count: numSamples)
        generator.getNextSamples(samples: &samples)
//        XCTAssertEqual(samples[0], amplitude, accuracy: epsilon)
//        XCTAssertEqual(samples[Int(generator.numSamplesInPeriod) / 2 - 1], amplitude, accuracy: epsilon)
//        XCTAssertEqual(samples[Int(generator.numSamplesInPeriod) / 2 + 1], -amplitude, accuracy: epsilon)
//        XCTAssertEqual(samples[Int(generator.numSamplesInPeriod)], amplitude, accuracy: epsilon)
    }
}
