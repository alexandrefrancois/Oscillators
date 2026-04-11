/**
MIT License

Copyright (c) 2026 Alexandre R. J. Francois

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
import OscillatorsCpp

final class TrackingResonatorBankVecTests: XCTestCase {
    let epsilon: Float = 1e-5

    func testInitialization() {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let gammas = TrackingResonatorBankArray.gammasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let trackingResonatorBank = TrackingResonatorBankVec(
            naturalFrequencies: frequencies,
            alphas: alphas,
            betas: betas,
            gammas: gammas,
            sampleRate: sampleRate)
        XCTAssertEqual(trackingResonatorBank.numResonators, frequencies.count, "Number of resonators mismatch")
        for i in 0..<trackingResonatorBank.numResonators {
            XCTAssertEqual(trackingResonatorBank.naturalFrequencies[i], FrequenciesFixtures.frequencies[i])
            XCTAssertEqual(trackingResonatorBank.alphas[i], Resonator.alphaHeuristic(frequency: trackingResonatorBank.naturalFrequencies[i], sampleRate: sampleRate, k: 1.0))
            XCTAssertEqual(trackingResonatorBank.omAlphas[i], Float(1.0) - trackingResonatorBank.alphas[i])
            XCTAssertEqual(trackingResonatorBank.betas[i], Resonator.alphaHeuristic(frequency: trackingResonatorBank.naturalFrequencies[i], sampleRate: sampleRate, k: 1.0))
            XCTAssertEqual(trackingResonatorBank.omBetas[i], Float(1.0) - trackingResonatorBank.betas[i])
            XCTAssertEqual(trackingResonatorBank.gammas[i], TrackingResonator.gammaHeuristic(frequency: trackingResonatorBank.naturalFrequencies[i], sampleRate: sampleRate, k: 1.0))
            XCTAssertEqual(trackingResonatorBank.omGammas[i], Float(1.0) - trackingResonatorBank.gammas[i])
            XCTAssertEqual(trackingResonatorBank.amplitudes[i], 0)
        }
    }

    func testUpdateAndReset() {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let gammas = TrackingResonatorBankArray.gammasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let trackingResonatorBank = TrackingResonatorBankVec(
            naturalFrequencies: frequencies,
            alphas: alphas,
            betas: betas,
            gammas: gammas,
            sampleRate: sampleRate)
        
        let N = 128
        let sine = SignalFixtures.makeSine(count: N, freq: 440.0, sampleRate: AudioFixtures.defaultSampleRate)
        trackingResonatorBank.update(frame: sine)
        let amps = trackingResonatorBank.amplitudes
        XCTAssertTrue(amps.reduce(false) { $0 || $1 > 0.0 })
        trackingResonatorBank.reset()
        let resonantFrequencies = trackingResonatorBank.resonantFrequencies
        for i in 0..<trackingResonatorBank.numResonators {
            XCTAssertEqual(resonantFrequencies[i], trackingResonatorBank.naturalFrequencies[i], accuracy: 1e-3)
        }
        let ampsAfterReset = trackingResonatorBank.amplitudes
        for val in ampsAfterReset {
            XCTAssertEqual(val, 0.0, accuracy: epsilon)
        }
    }

    func testFrameVsStepUpdateConsistency() {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let gammas = TrackingResonatorBankArray.gammasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let bankA = TrackingResonatorBankVec(naturalFrequencies: frequencies, alphas: alphas, betas: betas, gammas: gammas, sampleRate: AudioFixtures.defaultSampleRate)
        let bankB = TrackingResonatorBankVec(naturalFrequencies: frequencies, alphas: alphas, betas: betas, gammas: gammas, sampleRate: AudioFixtures.defaultSampleRate)
        let frame = SignalFixtures.makeSine(count: 100, freq: 440.0, sampleRate: AudioFixtures.defaultSampleRate)
        bankA.update(frame: frame)
        for x in frame { bankB.update(sample: x) }
        XCTAssertEqual(bankA.amplitudes[0], bankB.amplitudes[0], accuracy: epsilon)
        XCTAssertEqual(bankA.phases[0], bankB.phases[0], accuracy: 1e-3)
    }

    func testBankVsStandaloneResonator() {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let gammas = TrackingResonatorBankArray.gammasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let N = 128
        let fx = 12
        let frame = SignalFixtures.makeSine(count: N, freq: frequencies[fx], sampleRate: sampleRate)
        let bank = TrackingResonatorBankVec(naturalFrequencies: frequencies, alphas: alphas, betas: betas, gammas: gammas, sampleRate: sampleRate)
        let standAlone = TrackingResonator(naturalFrequency: frequencies[fx], alpha: alphas[fx], beta: betas[fx], gamma: gammas[fx], sampleRate: sampleRate)
        for x in frame {
            bank.update(sample: x)
            standAlone.updateWithSample(x)
        }
        let ampBank = bank.amplitudes[fx]
        let ampSolo = standAlone.amplitude
        XCTAssertEqual(ampBank, ampSolo, accuracy: 1e-4)
        let phaseBank = bank.phases[fx]
        let phaseSolo = standAlone.phase
        XCTAssertEqual(phaseBank, phaseSolo, accuracy: 1e-4)
    }

    func testSwiftAndCppBankParity() {
        let frequencies = FrequenciesFixtures.frequencies
        let sampleRate = AudioFixtures.defaultSampleRate
        let alphas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let betas = ResonatorBankArray.alphasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let gammas = TrackingResonatorBankArray.gammasHeuristic(frequencies: frequencies, sampleRate: sampleRate, k: 1.0)
        let N = 512
        var frame = SignalFixtures.makeSine(count: N, freq: 220.0, sampleRate: sampleRate)
        let swiftBank = TrackingResonatorBankVec(
            naturalFrequencies: frequencies,
            alphas: alphas,
            betas: betas,
            gammas: gammas,
            sampleRate: sampleRate)
        guard let cppBank = TrackingResonatorBankVecCpp(
            numResonators: Int32(frequencies.count),
            naturalFrequencies: frequencies,
            alphas: alphas,
            betas: betas,
            gammas: gammas,
            sampleRate: sampleRate) else {
            XCTFail("Cpp TrackingResonatorBankVec could not be instantiated"); return
        }
        
        swiftBank.update(frame: frame)
        cppBank.update(frameData: &frame, frameLength: Int32(N), sampleStride: 1)

        // Compare amplitudes and phases elementwise with tolerance
        var cppAmplitudes = [Float](repeating: 0.0, count: frequencies.count)
        cppBank.getAmplitudes(&cppAmplitudes, size: Int32(cppAmplitudes.count))
        var cppPhases = [Float](repeating: 0.0, count: frequencies.count)
        cppBank.getPhases(&cppPhases, size: Int32(cppPhases.count))
        for i in 0..<swiftBank.numResonators {
            XCTAssertEqual(swiftBank.amplitudes[i], cppAmplitudes[i], accuracy: 1e-4, "Amplitude mismatch at index \(i)")
            XCTAssertEqual(swiftBank.phases[i], cppPhases[i], accuracy: 1e-4, "Phase mismatch at index \(i)")
        }
    }
}
