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

final class ResonatorBankArrayTests: XCTestCase {
    func testConstructorFromFrequencies() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let alphas = frequencies.map {
            Frequencies.alphaHeuristic(frequency: $0, sampleRate: AudioFixtures.defaultSampleRate)
        }
        let resonatorBankArray = ResonatorBankArray(frequencies: frequencies,
                                                    alphas: alphas,
                                                    sampleRate: AudioFixtures.defaultSampleRate)
        
        XCTAssertEqual(resonatorBankArray.resonators.count, frequencies.count)
        for (index, resonator) in resonatorBankArray.resonators.enumerated() {
            XCTAssertEqual(resonator.alpha, Frequencies.alphaHeuristic(frequency: resonator.frequency, sampleRate: AudioFixtures.defaultSampleRate))
            XCTAssertEqual(resonator.frequency, frequencies[index])
        }
    }
 
    func testConstructorWithAlphaHeuristics() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let resonatorBankArray = ResonatorBankArray(frequencies: frequencies,
                                                    sampleRate: AudioFixtures.defaultSampleRate,
                                                    alphaHeuristic: Frequencies.alphaHeuristic(frequency:sampleRate:))
        
        XCTAssertEqual(resonatorBankArray.resonators.count, frequencies.count)
        for (index, resonator) in resonatorBankArray.resonators.enumerated() {
            XCTAssertEqual(resonator.frequency, frequencies[index])
            XCTAssertEqual(resonator.alpha, Frequencies.alphaHeuristic(frequency: resonator.frequency, sampleRate: AudioFixtures.defaultSampleRate))
        }
    }
    
    func testConstructorFromAlphas() throws {
        let frequency : Float = 440.0
        let alphas = DynamicsFixtures.alphas
        let resonatorBankArray = ResonatorBankArray(alphas: alphas,
                                                    sampleRate: AudioFixtures.defaultSampleRate,
                                                    frequency: frequency)
        
        XCTAssertEqual(resonatorBankArray.resonators.count, alphas.count)
        for (index, resonator) in resonatorBankArray.resonators.enumerated() {
            XCTAssertEqual(resonator.alpha, alphas[index])
            XCTAssertEqual(resonator.frequency, frequency)
        }

    }

    func testUpdate() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let alphas = frequencies.map {
            Frequencies.alphaHeuristic(frequency: $0, sampleRate: AudioFixtures.defaultSampleRate)
        }
        let resonatorBankArray = ResonatorBankArray(frequencies: frequencies,
                                                    alphas: alphas,
                                                    sampleRate: AudioFixtures.defaultSampleRate)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        resonatorBankArray.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        let amplitudes = resonatorBankArray.amplitudes
        for value in amplitudes {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        frame.deallocate()
    }
  
    func testUpdateConcurrent() throws {
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        
        // even number of oscillators
        let frequenciesEven: [Float] = [5512.5, 6300.0005, 7350.0005, 8820.0]
        let alphasEven = frequenciesEven.map {
            Frequencies.alphaHeuristic(frequency: $0, sampleRate: AudioFixtures.defaultSampleRate)
        }
        let resonatorBankArray1 = ResonatorBankArray(frequencies: frequenciesEven,
                                                     alphas: alphasEven,
                                                     sampleRate: AudioFixtures.defaultSampleRate)
        resonatorBankArray1.updateConcurrent(frameData: frame, frameLength: 1024, sampleStride: 1)
        let amplitudes1 = resonatorBankArray1.amplitudes
        for value in amplitudes1 {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        
        // odd number of oscillators
        let frequenciesOdd: [Float] = [5512.5, 6300.0005, 7350.0005, 8820.0]
        let alphasOdd = frequenciesOdd.map {
            Frequencies.alphaHeuristic(frequency: $0, sampleRate: AudioFixtures.defaultSampleRate)
        }
        let resonatorBankArray2 = ResonatorBankArray(frequencies: frequenciesOdd,
                                                     alphas: alphasOdd,
                                                     sampleRate: AudioFixtures.defaultSampleRate)
        resonatorBankArray2.updateConcurrent(frameData: frame, frameLength: 1024, sampleStride: 1)
        let amplitudes2 = resonatorBankArray2.amplitudes
        for value in amplitudes2 {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }

        frame.deallocate()
    }
}
