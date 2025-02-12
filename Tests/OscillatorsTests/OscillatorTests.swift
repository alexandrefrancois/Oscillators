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

fileprivate let epsilon : Float = 0.0001
fileprivate let twoPi = Float.pi * 2.0

final class OscillatorTests: XCTestCase {
        
    func testConstructor() throws {
        let frequency = Float(440.0)
        let sampleRate = AudioFixtures.defaultSampleRate
        
        let oscillator = Oscillator(frequency: frequency, sampleRate: sampleRate)
        
        XCTAssertEqual(oscillator.sampleRate, AudioFixtures.defaultSampleRate)
        XCTAssertEqual(oscillator.frequency, frequency)
        XCTAssertEqual(oscillator.sampleRate, sampleRate)
        XCTAssertEqual(oscillator.amplitude, 1.0)
    }
    
    func testGetNextSample() throws {
        let amplitude : Float = 0.5
        let oscillator = Oscillator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, amplitude: amplitude)
        let nextSample = oscillator.getNextSample()
        XCTAssertEqual(nextSample, amplitude, accuracy: epsilon)
    }
    
    func testGetNextSamples1() throws {
        let frequency : Float = 440.0
        let amplitude : Float = 0.5
        let sampleRate = AudioFixtures.defaultSampleRate
        let oscillator = Oscillator(frequency: frequency, sampleRate: sampleRate, amplitude: amplitude)
        let numSamples = 10000
        let samples = oscillator.getNextSamples(numSamples: numSamples)
        XCTAssertEqual(samples.count, numSamples)
        
        let twoPiFrequency : Float = twoPi * frequency
        let delta : Float = twoPiFrequency / sampleRate
        XCTAssertEqual(samples[0], amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[666], amplitude * cos(666 * delta), accuracy: epsilon)
        XCTAssertEqual(samples[3333], amplitude * cos(3333 * delta), accuracy: epsilon)
        XCTAssertEqual(samples[7777], amplitude * cos(7777 * delta), accuracy: epsilon)
        XCTAssertEqual(samples[9999], amplitude * cos(9999 * delta), accuracy: epsilon)
    }

    func testGetNextSamples2() throws {
        let frequency : Float = 440.0
        let amplitude : Float = 0.5
        let sampleRate = AudioFixtures.defaultSampleRate
        let oscillator = Oscillator(frequency: frequency, sampleRate: sampleRate, amplitude: amplitude)
        let numSamples = 10000
        var samples = [Float](repeating: 0.0, count: numSamples)
        oscillator.getNextSamples(samples: &samples)
        
        let twoPiFrequency : Float = twoPi * frequency
        let delta : Float = twoPiFrequency / sampleRate
        XCTAssertEqual(samples[0], amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[666], amplitude * cos(666 * delta), accuracy: epsilon)
        XCTAssertEqual(samples[3333], amplitude * cos(3333 * delta), accuracy: epsilon)
        XCTAssertEqual(samples[7777], amplitude * cos(7777 * delta), accuracy: epsilon)
        XCTAssertEqual(samples[9999], amplitude * cos(9999 * delta), accuracy: epsilon)
    }
}
