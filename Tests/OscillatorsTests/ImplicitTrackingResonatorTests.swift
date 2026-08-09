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

final class ImplicitTrackingResonatorTests: XCTestCase {
    private let sampleRate = AudioFixtures.defaultSampleRate
    private let rules: [ImplicitTrackingRule] = [.normalizedChord, .tangent]

    func testConstruction() {
        for rule in rules {
            let resonator = makeResonator(rule: rule, naturalFrequency: 440.0, alpha: 0.01, beta: 0.02, gamma: 0.03)

            XCTAssertEqual(resonator.alpha, 0.01)
            XCTAssertEqual(resonator.beta, 0.02)
            XCTAssertEqual(resonator.gamma, 0.03)
            XCTAssertEqual(resonator.trackingRule, rule)
            XCTAssertEqual(resonator.naturalFrequency, 440.0)
            XCTAssertEqual(resonator.resonantFrequency, 440.0, accuracy: 1e-4)
        }
    }

    func testSetAlphaBetaGamma() {
        for rule in rules {
            let resonator = makeResonator(rule: rule, naturalFrequency: 440.0, alpha: 0.2, beta: 0.3, gamma: 0.4)

            resonator.alpha = 0.11
            resonator.beta = 0.22
            resonator.gamma = 0.33

            XCTAssertEqual(resonator.alpha, 0.11)
            XCTAssertEqual(resonator.omAlpha, 0.89, accuracy: 1e-6)
            XCTAssertEqual(resonator.beta, 0.22)
            XCTAssertEqual(resonator.omBeta, 0.78, accuracy: 1e-6)
            XCTAssertEqual(resonator.gamma, 0.33)
            XCTAssertEqual(resonator.omGamma, 0.67, accuracy: 1e-6)
        }
    }

    func testSingleSampleAccumulationMatchesLegacyWhenGammaIsZero() {
        for rule in rules {
            let implicit = makeResonator(rule: rule, naturalFrequency: 440.0, alpha: 1.0, beta: 1.0, gamma: 0.0)
            let legacy = TrackingResonator(naturalFrequency: 440.0, alpha: 1.0, beta: 1.0, gamma: 0.0, sampleRate: sampleRate)

            implicit.updateWithSample(1.0)
            legacy.updateWithSample(1.0)

            XCTAssertEqual(implicit.c, legacy.c, accuracy: 1e-6)
            XCTAssertEqual(implicit.s, legacy.s, accuracy: 1e-6)
            XCTAssertEqual(implicit.cc, legacy.cc, accuracy: 1e-6)
            XCTAssertEqual(implicit.ss, legacy.ss, accuracy: 1e-6)
        }
    }

    func testGammaZeroDoesNotChangeMultiplierWithSufficientPower() {
        for rule in rules {
            let resonator = makeResonator(rule: rule, naturalFrequency: 440.0, alpha: 0.1, beta: 0.1, gamma: 0.0)
            let initialWc = resonator.Wc
            let initialWs = resonator.Ws
            let signal = TrackingSignalFixtures.constantTone(
                count: 2_000,
                frequency: 470.0,
                amplitude: 1.0,
                sampleRate: sampleRate
            ).samples

            resonator.update(samples: signal, maxPower: 1.0)

            XCTAssertEqual(resonator.Wc, initialWc, accuracy: 1e-5)
            XCTAssertEqual(resonator.Ws, initialWs, accuracy: 1e-5)
            XCTAssertGreaterThan(resonator.amplitude, 0.0)
        }
    }

    func testNaturalFrequencyResetOnWeakInput() {
        for rule in rules {
            let resonator = makeResonator(rule: rule, naturalFrequency: 400.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
            let tone = TrackingSignalFixtures.constantTone(
                count: 20_000,
                frequency: 440.0,
                amplitude: 1.0,
                sampleRate: sampleRate
            ).samples
            resonator.update(samples: tone, maxPower: 1.0)
            XCTAssertNotEqual(resonator.resonantFrequency, resonator.naturalFrequency, accuracy: 0.1)

            resonator.update(samples: [Float](repeating: 0.0, count: 5_000), maxPower: 1.0)

            XCTAssertEqual(resonator.resonantFrequency, resonator.naturalFrequency, accuracy: 1e-4)
            XCTAssertEqual(resonator.Wc * resonator.Wc + resonator.Ws * resonator.Ws, 1.0, accuracy: 1e-5)
        }
    }

    func testMultiplierNormDuringLongTrackingRun() {
        for rule in rules {
            let resonator = makeResonator(rule: rule, naturalFrequency: 430.0, alpha: 0.01, beta: 0.01, gamma: 0.005)
            let signal = TrackingSignalFixtures.constantTone(
                count: 300_000,
                frequency: 440.0,
                amplitude: 1.0,
                sampleRate: sampleRate
            ).samples

            resonator.update(samples: signal, maxPower: 1.0)

            XCTAssertEqual(resonator.Wc * resonator.Wc + resonator.Ws * resonator.Ws, 1.0, accuracy: 2e-5)
        }
    }

    func testFiniteStateForPathologicalInputs() {
        for rule in rules {
            let inputs: [[Float]] = [
                [Float](repeating: 0.0, count: 1_000),
                SignalFixtures.makeImpulse(count: 1_000),
                TrackingSignalFixtures.constantTone(count: 1_000, frequency: 440.0, amplitude: 1e-8, sampleRate: sampleRate).samples,
                [Float](repeating: 1.0, count: 1_000),
                TrackingSignalFixtures.constantTone(count: 5_000, frequency: 440.0, amplitude: 1.0, sampleRate: sampleRate).samples
            ]

            for input in inputs {
                let resonator = makeResonator(rule: rule, naturalFrequency: 440.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
                resonator.update(samples: input, maxPower: 1.0)
                assertFiniteState(resonator)
            }
        }
    }

    func testDirectionOfAdaptation() {
        for rule in rules {
            let lowStart = makeResonator(rule: rule, naturalFrequency: 400.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
            let highStart = makeResonator(rule: rule, naturalFrequency: 480.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
            let tone = TrackingSignalFixtures.constantTone(
                count: 50_000,
                frequency: 440.0,
                amplitude: 1.0,
                sampleRate: sampleRate
            ).samples

            lowStart.update(samples: tone, maxPower: 1.0)
            highStart.update(samples: tone, maxPower: 1.0)

            XCTAssertGreaterThan(lowStart.resonantFrequency, 400.0)
            XCTAssertLessThan(highStart.resonantFrequency, 480.0)
        }
    }

    func testBatchEquivalence() {
        for rule in rules {
            let samples = TrackingSignalFixtures.constantTone(
                count: 1_024,
                frequency: 440.0,
                amplitude: 1.0,
                sampleRate: sampleRate
            ).samples
            let sampleBySample = makeResonator(rule: rule, naturalFrequency: 430.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
            let batched = makeResonator(rule: rule, naturalFrequency: 430.0, alpha: 0.01, beta: 0.01, gamma: 0.01)

            for sample in samples {
                sampleBySample.update(sample: sample, maxPower: 1.0)
            }
            batched.update(samples: samples, maxPower: 1.0)

            XCTAssertEqual(sampleBySample.amplitude, batched.amplitude, accuracy: 1e-4)
            XCTAssertEqual(sampleBySample.resonantFrequency, batched.resonantFrequency, accuracy: 1e-3)
        }
    }

    func testBufferEquivalence() {
        for rule in rules {
            let frameLength = 512
            let samples = TrackingSignalFixtures.constantTone(
                count: frameLength,
                frequency: 440.0,
                amplitude: 1.0,
                sampleRate: sampleRate
            ).samples
            var interleaved = samples.flatMap { [$0, Float(-0.25)] }
            let reference = makeResonator(rule: rule, naturalFrequency: 430.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
            let strided = makeResonator(rule: rule, naturalFrequency: 430.0, alpha: 0.01, beta: 0.01, gamma: 0.01)

            reference.update(samples: samples, maxPower: 1.0)
            interleaved.withUnsafeMutableBufferPointer { buffer in
                strided.update(frameData: buffer.baseAddress!, frameLength: frameLength, sampleStride: 2, maxPower: 1.0)
            }

            XCTAssertEqual(strided.amplitude, reference.amplitude, accuracy: 1e-5)
            XCTAssertEqual(strided.resonantFrequency, reference.resonantFrequency, accuracy: 1e-4)
        }
    }

    func testTracksWithoutIntermediateFrequencyReadout() {
        let resonator = makeResonator(rule: .normalizedChord, naturalFrequency: 430.0, alpha: 0.01, beta: 0.01, gamma: 0.01)
        let signal = TrackingSignalFixtures.constantTone(
            count: 50_000,
            frequency: 440.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        ).samples

        for sample in signal {
            resonator.updateWithSample(sample)
        }

        XCTAssertEqual(resonator.Wc * resonator.Wc + resonator.Ws * resonator.Ws, 1.0, accuracy: 2e-5)
        // Frequency is represented implicitly by the phasor multiplier. atan2 is
        // used here only to observe that state in Hz for testing.
        XCTAssertEqual(resonator.resonantFrequency, 440.0, accuracy: 2.0)
    }

    private func makeResonator(
        rule: ImplicitTrackingRule,
        naturalFrequency: Float,
        alpha: Float,
        beta: Float,
        gamma: Float
    ) -> ImplicitTrackingResonator {
        ImplicitTrackingResonator(
            naturalFrequency: naturalFrequency,
            alpha: alpha,
            beta: beta,
            gamma: gamma,
            sampleRate: sampleRate,
            trackingRule: rule
        )
    }

    private func assertFiniteState(_ resonator: ImplicitTrackingResonator, file: StaticString = #filePath, line: UInt = #line) {
        let values = [
            resonator.c,
            resonator.s,
            resonator.cc,
            resonator.ss,
            resonator.dpc,
            resonator.dps,
            resonator.Wc,
            resonator.Ws,
            resonator.Zc,
            resonator.Zs,
            resonator.resonantFrequency,
            resonator.amplitude,
            resonator.power
        ]

        for value in values {
            XCTAssertTrue(value.isFinite, file: file, line: line)
        }
    }
}
