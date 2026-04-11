/**
MIT License

Copyright (c) 2022-2026 Alexandre R. J. Francois

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

final class ResonatorBankVecTests: XCTestCase {
    // Test constructor initializes ResonatorBankVec with correct resonators and zero amplitudes
    func testConstructor() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let resonatorBank = ResonatorBankVec(frequencies: frequencies,
                                             alphas: alphas,
                                             betas: betas,
                                             sampleRate: sampleRate)

        XCTAssertEqual(resonatorBank.numResonators, frequencies.count, "Number of resonators mismatch")

        for i in 0..<resonatorBank.numResonators {
            XCTAssertEqual(resonatorBank.frequencies[i], FrequenciesFixtures.frequencies[i])
            XCTAssertEqual(resonatorBank.alphas[i], Resonator.alphaHeuristic(frequency: resonatorBank.frequencies[i], sampleRate: sampleRate, k: 1.0))
            XCTAssertEqual(resonatorBank.omAlphas[i], Float(1.0) - resonatorBank.alphas[i])
            XCTAssertEqual(resonatorBank.betas[i], Resonator.alphaHeuristic(frequency: resonatorBank.frequencies[i], sampleRate: sampleRate, k: 1.0))
            XCTAssertEqual(resonatorBank.omBetas[i], Float(1.0) - resonatorBank.betas[i])
            XCTAssertEqual(resonatorBank.amplitudes[i], 0)
        }
    }
    
    // Test update method modifies amplitudes appropriately based on input frame
    func testUpdate() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let resonatorBank = ResonatorBankVec(frequencies: frequencies,
                                             alphas: alphas,
                                             betas: betas,
                                             sampleRate: sampleRate)
        
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        resonatorBank.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        let amplitudes = resonatorBank.amplitudes
        for value in amplitudes {
            XCTAssertGreaterThan(value, 0.0, "Resonator not updated")
        }
        frame.deallocate()
    }
    
    // Test update and reset: update with known frame, check nonzero amplitudes and powers, then reset to zero powers
    func testUpdateAndReset() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let resonatorBank = ResonatorBankVec(frequencies: frequencies,
                                             alphas: alphas,
                                             betas: betas,
                                             sampleRate: sampleRate)
        
        let frameLength = 512
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: frameLength)
        frame.initialize(repeating: 1.0, count: frameLength)
        
        resonatorBank.update(frameData: frame, frameLength: frameLength, sampleStride: 1)
        
        // Check amplitudes and powers are nonzero after update
        XCTAssertTrue(resonatorBank.amplitudes.allSatisfy { $0 > 0 }, "Amplitudes should be greater than zero after update")
        XCTAssertTrue(resonatorBank.powers.allSatisfy { $0 > 0 }, "Powers should be greater than zero after update")
        
        // Reset powers and check all zero
        resonatorBank.reset()
        XCTAssertTrue(resonatorBank.powers.allSatisfy { $0 == 0 }, "Powers should be zero after reset")
        
        frame.deallocate()
    }
    
    // Test single-element ResonatorBankVec matches standalone Resonator output for given input frame
    func testSingleResonatorComparison() throws {
        let frequency: Float = 440.0
        let sampleRate = AudioFixtures.defaultSampleRate
        let alpha = Resonator.alphaHeuristic(frequency: frequency, sampleRate: sampleRate)
        let beta = Float(0.5) // arbitrary beta for test
        
        let resonatorBank = ResonatorBankVec(frequencies: [frequency],
                                             alphas: [alpha],
                                             betas: [beta],
                                             sampleRate: sampleRate)
        let resonator = Resonator(frequency: frequency, alpha: alpha, beta: beta, sampleRate: sampleRate)
        
        let frameLength = 256
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: frameLength)
        // Use a fixed input: sine wave at frequency 440 Hz for test
        for i in 0..<frameLength {
            frame[i] = sin(2.0 * Float.pi * frequency * Float(i) / sampleRate)
        }
        
        resonatorBank.update(frameData: frame, frameLength: frameLength, sampleStride: 1)
        resonator.update(frameData: frame, frameLength: frameLength, sampleStride: 1)
        
        // Compare amplitudes and phases with tolerance
        let bankAmp = resonatorBank.amplitudes[0]
        let resAmp = resonator.amplitude
        
        XCTAssertEqual(bankAmp, resAmp, accuracy: 1e-4, "Amplitudes differ for single resonator")
        
        let bankPhase = resonatorBank.phases[0]
        let resPhase = resonator.phase
        
        XCTAssertEqual(bankPhase, resPhase, accuracy: 1e-4, "Phases differ for single resonator")
        
        frame.deallocate()
    }
    
    // Cross-implementation test comparing ResonatorBankVec (Swift) and ResonatorBankVecCpp (C++ wrapper) output
    func testCrossImplementationComparison() throws {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)

        // Swift implementation
        let resonatorBankSwift = ResonatorBankVec(frequencies: frequencies,
                                                  alphas: alphas,
                                                  betas: betas,
                                                  sampleRate: sampleRate)
        // C++ wrapper
        guard let resonatorBankCpp = ResonatorBankVecCpp(numResonators: Int32(frequencies.count),
                                                         frequencies: frequencies,
                                                         alphas: alphas,
                                                         betas: betas,
                                                         sampleRate: sampleRate) else {
            XCTFail("Cpp TrackingResonator could not be instantiated"); return
        }
        
        let frameLength = 512
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: frameLength)
        // Fill with random values between -1 and 1 for testing
        for i in 0..<frameLength {
            frame[i] = Float.random(in: -1.0...1.0)
        }
        
        resonatorBankSwift.update(frameData: frame, frameLength: frameLength, sampleStride: 1)
        resonatorBankCpp.update(frameData: frame, frameLength: Int32(frameLength), sampleStride: 1)
        
        // Compare amplitudes and phases elementwise with tolerance
        var cppAmplitudes = [Float](repeating: 0.0, count: frequencies.count)
        resonatorBankCpp.getAmplitudes(&cppAmplitudes, size: Int32(cppAmplitudes.count))
        var cppPhases = [Float](repeating: 0.0, count: frequencies.count)
        resonatorBankCpp.getPhases(&cppPhases, size: Int32(cppPhases.count))
        for i in 0..<resonatorBankSwift.numResonators {
            XCTAssertEqual(resonatorBankSwift.amplitudes[i], cppAmplitudes[i], accuracy: 1e-4, "Amplitude mismatch at index \(i)")
            XCTAssertEqual(resonatorBankSwift.phases[i], cppPhases[i], accuracy: 1e-4, "Phase mismatch at index \(i)")
        }
        
        frame.deallocate()
    }
}
