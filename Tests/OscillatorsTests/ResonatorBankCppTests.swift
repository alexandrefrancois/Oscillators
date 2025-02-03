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
@testable import OscillatorsCpp

final class ResonatorBankCppTests: XCTestCase {
    func testConstructorFromFrequencies() throws {
        var frequencies = FrequenciesFixtures.frequencies
        var alphas = [Float](repeating: DynamicsFixtures.defaultAlpha, count: frequencies.count)
        let resonatorBankCpp = ResonatorBankCpp(numResonators: (Int32)(frequencies.count),
                                                frequencies: &frequencies,
                                                alphas: &alphas,
                                                sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonatorBankCpp = resonatorBankCpp else { return XCTAssert(false) }

        XCTAssertEqual((Int)(resonatorBankCpp.numResonators()), frequencies.count)
        for index in 0..<resonatorBankCpp.numResonators() {
            XCTAssertEqual(resonatorBankCpp.alphaValue(index), DynamicsFixtures.defaultAlpha)
        }
    }

    func testUpdate() throws {
        var freqs: [Float] = [5512.5, 6300.0005, 7350.0005, 8820.0]
        var alphas = [Float](repeating: DynamicsFixtures.defaultAlpha, count: freqs.count)
        let resonatorBankCpp = ResonatorBankCpp(numResonators: (Int32)(freqs.count),
                                                frequencies: &freqs,
                                                alphas: &alphas,
                                                sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonatorBankCpp = resonatorBankCpp else { return XCTAssert(false) }

        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)

        resonatorBankCpp.update(frameData: frame, frameLength: 1024, sampleStride: 1)

        // get values for all amplitudes
        let size = resonatorBankCpp.numResonators()
        var amplitudes = [Float](repeating: 0.0, count: Int(size))
        resonatorBankCpp.copyAmplitudes(&amplitudes, size: size)
        for value in amplitudes {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        
        frame.deallocate()
    }
  
    func testUpdateConcurrent() throws {
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)

        // even number of oscillators
        var freqs1: [Float] = [5512.5, 6300.0005, 7350.0005, 8820.0]
        var alphas1 = [Float](repeating: DynamicsFixtures.defaultAlpha, count: freqs1.count)
        let resonatorBankCpp1 = ResonatorBankCpp(numResonators: (Int32)(freqs1.count),
                                                 frequencies: &freqs1,
                                                 alphas: &alphas1,
                                                 sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonatorBankCpp1 = resonatorBankCpp1 else { return XCTAssert(false) }

        resonatorBankCpp1.updateConcurrent(frameData: frame, frameLength: 1024, sampleStride: 1)

        // get values for all amplitudes
        let size1 = resonatorBankCpp1.numResonators()
        var amplitudes1 = [Float](repeating: 0.0, count: Int(size1))
        resonatorBankCpp1.copyAmplitudes(&amplitudes1, size: size1)
        for value in amplitudes1 {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        
        // odd number of oscillators
        var freqs2: [Float] = [6300.0005, 7350.0005, 8820.0]
        var alphas2 = [Float](repeating: DynamicsFixtures.defaultAlpha, count: freqs2.count)
        let resonatorBankCpp2 = ResonatorBankCpp(numResonators: (Int32)(freqs2.count),
                                                 frequencies: &freqs2,
                                                 alphas: &alphas2,
                                                 sampleRate: AudioFixtures.defaultSampleRate)
        guard let resonatorBankCpp2 = resonatorBankCpp2 else { return XCTAssert(false) }

        resonatorBankCpp2.updateConcurrent(frameData: frame, frameLength: 1024, sampleStride: 1)

        // get values for all amplitudes
        let size2 = resonatorBankCpp2.numResonators()
        var amplitudes2 = [Float](repeating: 0.0, count: Int(size2))
        resonatorBankCpp2.copyAmplitudes(&amplitudes2, size: size2)
        for value in amplitudes2 {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }

        frame.deallocate()
    }
}
