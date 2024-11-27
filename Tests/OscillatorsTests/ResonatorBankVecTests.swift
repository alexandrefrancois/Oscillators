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
@testable import Oscillators

final class ResonatorBankVecTests: XCTestCase {
    func testConstructor() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let alphas = frequencies.map {
            Frequencies.alphaHeuristic(frequency: $0, sampleRate: AudioFixtures.defaultSampleRate)
        }
        let resonatorBank = ResonatorBankVec(frequencies: frequencies,
                                             sampleRate: AudioFixtures.defaultSampleRate,
                                             alphas: alphas)
                
        for i in 0..<resonatorBank.numResonators {
            XCTAssertEqual(resonatorBank.alphas[i], Frequencies.alphaHeuristic(frequency: resonatorBank.frequencies[i], sampleRate: AudioFixtures.defaultSampleRate))
            XCTAssertEqual(resonatorBank.amplitudes[i], 0)
        }
    }
    
    func testUpdate() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let alphas = frequencies.map {
            Frequencies.alphaHeuristic(frequency: $0, sampleRate: AudioFixtures.defaultSampleRate)
        }
        let resonatorBank = ResonatorBankVec(frequencies: frequencies,
                                             sampleRate: AudioFixtures.defaultSampleRate,
                                             alphas: alphas)
        
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        resonatorBank.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        let amplitudes = resonatorBank.amplitudes
        for value in amplitudes {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        frame.deallocate()
    }
}
