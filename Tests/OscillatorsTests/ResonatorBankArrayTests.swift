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

final class ResonatorBankArrayTests: XCTestCase {
    func testConstructorFromFrequencies() throws {
        let targetFrequencies = FrequenciesFixtures.targetFrequencies
        let expectedFrequencies = targetFrequencies.map { targetFrequency in
            Frequencies.closestFrequency(targetFrequency: targetFrequency, sampleDuration: AudioFixtures.sampleDuration44100)
        }
        let resonatorBankArray = ResonatorBankArray(targetFrequencies: targetFrequencies,
                                                    sampleDuration: AudioFixtures.sampleDuration44100,
                                                    alpha: DynamicsFixtures.defaultAlpha)
        
        XCTAssertEqual(resonatorBankArray.resonators.count, targetFrequencies.count)
        for (index, resonator) in resonatorBankArray.resonators.enumerated() {
            XCTAssertEqual(resonator.alpha, DynamicsFixtures.defaultAlpha)
            XCTAssertEqual(resonator.frequency, expectedFrequencies[index])
        }
    }
 
    func testConstructorFromAlphas() throws {
        let targetFrequency : Float = 440.0
        let expectedFrequency : Float = 441.0
        let alphas = DynamicsFixtures.alphas
        let resonatorBankArray = ResonatorBankArray(alphas: alphas,
                                                    sampleDuration: AudioFixtures.sampleDuration44100,
                                                    targetFrequency: targetFrequency)
        
        XCTAssertEqual(resonatorBankArray.resonators.count, alphas.count)
        for (index, resonator) in resonatorBankArray.resonators.enumerated() {
            XCTAssertEqual(resonator.alpha, alphas[index])
            XCTAssertEqual(resonator.frequency, expectedFrequency)
        }

    }

    func testUpdateSeq() throws {
        let resonatorBankArray = ResonatorBankArray(targetFrequencies: [5512.5, 6300.0005, 7350.0005, 8820.0],
                                                    sampleDuration: AudioFixtures.sampleDuration44100,
                                                    alpha: DynamicsFixtures.defaultAlpha)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        resonatorBankArray.updateSeq(frameData: frame, frameLength: 1024, sampleStride: 1)
        let maxima = resonatorBankArray.maxima
        for value in maxima {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        frame.deallocate()
    }
  
    func testUpdate() throws {
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        
        // even number of oscillators
        let resonatorBankArray1 = ResonatorBankArray(targetFrequencies: [5512.5, 6300.0005, 7350.0005, 8820.0],
                                                     sampleDuration: AudioFixtures.sampleDuration44100,
                                                     alpha: DynamicsFixtures.defaultAlpha)
        resonatorBankArray1.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        let maxima1 = resonatorBankArray1.maxima
        for value in maxima1 {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        // odd number of oscillators
        let resonatorBankArray2 = ResonatorBankArray(targetFrequencies: [6300.0005, 7350.0005, 8820.0],
                                                     sampleDuration: AudioFixtures.sampleDuration44100,
                                                     alpha: DynamicsFixtures.defaultAlpha)
        resonatorBankArray2.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        let maxima2 = resonatorBankArray2.maxima
        for value in maxima2 {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }

        frame.deallocate()
    }
    
    // This test is not really meaningful
//    func testUpdatePerf() async throws {
//        let resonatorBankArray = ResonatorBankArray(targetFrequencies: targetFrequencies, sampleDuration: AudioFixtures.sampleDuration44100, alpha: defaultAlpha)
//        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
//        frame.initialize(repeating: 0.5, count: 1024)
//        measure {
//            // this test does not work with the concurrent version
//            resonatorBankArray.updateSeq(frameData: frame, frameLength: 1024, sampleStride: 1)
//        }
//        frame.deallocate()
//    }

}
