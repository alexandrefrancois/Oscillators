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

final class TrackingResonatorComparisonTests: XCTestCase {
    private let sampleRate = AudioFixtures.defaultSampleRate
    private let alpha: Float = 0.01
    private let beta: Float = 0.01
    private let gamma: Float = 0.01
    private let maxPower: Float = 1.0
    private let warmUpCount = 3_000
    private let settlingBand: Float = 1.0
    private let settlingHoldCount = Int(AudioFixtures.defaultSampleRate * 0.02)
    private let thresholdDivider: Float = 1000.0

    func testMatchedToneComparison() {
        let trace = TrackingSignalFixtures.constantTone(
            count: 12_000,
            frequency: 440.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        )

        let results = compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 440.0)
        assertFinite(results)
    }

    func testSmallInitialMismatchComparison() {
        let trace = TrackingSignalFixtures.constantTone(
            count: 16_000,
            frequency: 440.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        )

        let lowStart = compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 430.0)
        let highStart = compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 450.0)

        assertFinite(lowStart)
        assertFinite(highStart)
    }

    func testLargerMismatchComparison() {
        let trace = TrackingSignalFixtures.constantTone(
            count: 20_000,
            frequency: 440.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        )

        assertFinite(compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 400.0))
        assertFinite(compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 480.0))
    }

    func testFrequencyStepComparison() {
        let transitionIndex = 8_000
        let trace = TrackingSignalFixtures.frequencyStep(
            firstFrequency: 440.0,
            secondFrequency: 466.1638,
            transitionIndex: transitionIndex,
            count: 18_000,
            amplitude: 1.0,
            sampleRate: sampleRate
        )

        let results = compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 440.0)
        assertFinite(results)
        for result in results {
            XCTAssertTrue(result.metrics.overshoot.isFinite)
            XCTAssertTrue(result.metrics.reacquisitionSamples == nil || result.metrics.reacquisitionSamples! >= transitionIndex)
        }
    }

    func testChirpComparison() {
        let ascending = TrackingSignalFixtures.chirp(
            count: 18_000,
            startFrequency: 400.0,
            endFrequency: 500.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        )
        let descending = TrackingSignalFixtures.chirp(
            count: 18_000,
            startFrequency: 500.0,
            endFrequency: 400.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        )

        assertFinite(compare(samples: ascending.samples, targets: ascending.frequencies, naturalFrequency: 400.0))
        assertFinite(compare(samples: descending.samples, targets: descending.frequencies, naturalFrequency: 500.0))
    }

    func testVibratoComparison() {
        let trace = TrackingSignalFixtures.vibrato(
            count: 22_050,
            carrierFrequency: 440.0,
            modulationRate: 5.0,
            deviation: 10.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        )

        assertFinite(compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 440.0))
    }

    func testNoiseComparison() {
        for snr in [Float(40.0), 20.0, 10.0] {
            let trace = TrackingSignalFixtures.noisyTone(
                count: 16_000,
                frequency: 440.0,
                amplitude: 1.0,
                snrDecibels: snr,
                sampleRate: sampleRate
            )

            assertFinite(compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 440.0))
        }
    }

    func testDropoutComparison() {
        let dropoutRange = 6_000..<10_000
        let trace = TrackingSignalFixtures.amplitudeDropout(
            count: 18_000,
            frequency: 440.0,
            amplitude: 1.0,
            dropoutRange: dropoutRange,
            sampleRate: sampleRate
        )

        let results = compare(samples: trace.samples, targets: trace.frequencies, naturalFrequency: 440.0)
        assertFinite(results)
    }

    func testTwoToneComparison() {
        let samples = TrackingSignalFixtures.twoTone(
            count: 18_000,
            firstFrequency: 440.0,
            secondFrequency: 470.0,
            firstAmplitude: 1.0,
            secondAmplitude: 0.7,
            sampleRate: sampleRate
        )
        let targets = [Float](repeating: 440.0, count: samples.count)

        assertFinite(compare(samples: samples, targets: targets, naturalFrequency: 440.0))
    }

    func testRelativeUpdateThroughputExcludingFrequencyReadout() {
        let samples = TrackingSignalFixtures.chirp(
            count: 44_100,
            startFrequency: 400.0,
            endFrequency: 500.0,
            amplitude: 1.0,
            sampleRate: sampleRate
        ).samples

        let ewma = measureUpdateTime(method: .ewma, samples: samples, naturalFrequency: 440.0)
        let chord = measureUpdateTime(method: .normalizedChord, samples: samples, naturalFrequency: 440.0)
        let tangent = measureUpdateTime(method: .tangent, samples: samples, naturalFrequency: 440.0)

        XCTAssertGreaterThan(ewma, 0.0)
        XCTAssertGreaterThan(chord, 0.0)
        XCTAssertGreaterThan(tangent, 0.0)

        print("Relative update throughput, excluding frequency readout: ewma=1.00x chord=\(ewma / chord)x tangent=\(ewma / tangent)x")
    }

    private func compare(samples: [Float], targets: [Float], naturalFrequency: Float) -> [ComparisonResult] {
        TrackingMethod.allCases.map { method in
            let estimates = run(method: method, samples: samples, naturalFrequency: naturalFrequency)
            let metrics = Metrics(estimates: estimates, targets: targets, warmUpCount: warmUpCount, settlingBand: settlingBand, settlingHoldCount: settlingHoldCount)
            return ComparisonResult(method: method, metrics: metrics)
        }
    }

    private func run(method: TrackingMethod, samples: [Float], naturalFrequency: Float) -> [Float] {
        var estimates = [Float]()
        estimates.reserveCapacity(samples.count)

        switch method {
        case .ewma:
            let resonator = TrackingResonator(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, trackingRule: .ewma, sampleRate: sampleRate)
            for sample in samples {
                resonator.update(sample: sample, maxPower: maxPower, thresholdDivider: thresholdDivider)
                estimates.append(resonator.resonantFrequency)
            }
        case .normalizedChord:
            let resonator = TrackingResonator(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, trackingRule: .normalizedChord, sampleRate: sampleRate)
            for sample in samples {
                resonator.update(sample: sample, maxPower: maxPower, thresholdDivider: thresholdDivider)
                estimates.append(resonator.resonantFrequency)
            }
        case .tangent:
            let resonator = TrackingResonator(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, trackingRule: .tangent, sampleRate: sampleRate)
            for sample in samples {
                resonator.update(sample: sample, maxPower: maxPower, thresholdDivider: thresholdDivider)
                estimates.append(resonator.resonantFrequency)
            }
        }

        return estimates
    }

    private func measureUpdateTime(method: TrackingMethod, samples: [Float], naturalFrequency: Float) -> TimeInterval {
        let start = Date()

        switch method {
        case .ewma:
            let resonator = TrackingResonator(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, trackingRule: .ewma, sampleRate: sampleRate)
            resonator.update(samples: samples, maxPower: maxPower, thresholdDivider: thresholdDivider)
        case .normalizedChord:
            let resonator = TrackingResonator(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, trackingRule: .normalizedChord, sampleRate: sampleRate)
            resonator.update(samples: samples, maxPower: maxPower, thresholdDivider: thresholdDivider)
        case .tangent:
            let resonator = TrackingResonator(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, trackingRule: .tangent, sampleRate: sampleRate)
            resonator.update(samples: samples, maxPower: maxPower, thresholdDivider: thresholdDivider)
        }

        return Date().timeIntervalSince(start)
    }

    private func assertFinite(_ results: [ComparisonResult], file: StaticString = #filePath, line: UInt = #line) {
        for result in results {
            XCTAssertTrue(result.metrics.finalError.isFinite, file: file, line: line)
            XCTAssertTrue(result.metrics.rmsError.isFinite, file: file, line: line)
            XCTAssertTrue(result.metrics.centsError == nil || result.metrics.centsError!.isFinite, file: file, line: line)
            XCTAssertTrue(result.metrics.steadyStateJitter.isFinite, file: file, line: line)
            XCTAssertTrue(result.metrics.overshoot.isFinite, file: file, line: line)
        }
    }

    private enum TrackingMethod: CaseIterable {
        case ewma
        case normalizedChord
        case tangent
    }

    private struct ComparisonResult {
        let method: TrackingMethod
        let metrics: Metrics
    }

    private struct Metrics {
        let finalError: Float
        let rmsError: Float
        let centsError: Float?
        let settlingSamples: Int?
        let steadyStateJitter: Float
        let overshoot: Float
        let reacquisitionSamples: Int?

        init(estimates: [Float], targets: [Float], warmUpCount: Int, settlingBand: Float, settlingHoldCount: Int) {
            let count = min(estimates.count, targets.count)
            let lastEstimate = estimates[count - 1]
            let lastTarget = targets[count - 1]
            finalError = abs(lastEstimate - lastTarget)
            centsError = lastEstimate > 0.0 && lastTarget > 0.0 ? 1200.0 * log2(lastEstimate / lastTarget) : nil

            let start = min(warmUpCount, count - 1)
            let errors = (start..<count).map { estimates[$0] - targets[$0] }
            let squaredMean = errors.reduce(Float(0.0)) { $0 + $1 * $1 } / Float(max(errors.count, 1))
            rmsError = sqrt(squaredMean)

            let finalWindowStart = max(start, count - max(1, count / 5))
            let finalErrors = (finalWindowStart..<count).map { estimates[$0] - targets[$0] }
            let mean = finalErrors.reduce(Float(0.0), +) / Float(max(finalErrors.count, 1))
            let variance = finalErrors.reduce(Float(0.0)) { $0 + ($1 - mean) * ($1 - mean) } / Float(max(finalErrors.count, 1))
            steadyStateJitter = sqrt(variance)

            overshoot = zip(estimates, targets).map { abs($0 - $1) }.max() ?? 0.0
            settlingSamples = Self.settlingIndex(estimates: estimates, targets: targets, band: settlingBand, holdCount: settlingHoldCount, startIndex: start)
            reacquisitionSamples = Self.settlingIndex(estimates: estimates, targets: targets, band: settlingBand, holdCount: settlingHoldCount, startIndex: count / 2)
        }

        private static func settlingIndex(estimates: [Float], targets: [Float], band: Float, holdCount: Int, startIndex: Int) -> Int? {
            let count = min(estimates.count, targets.count)
            guard holdCount > 0, startIndex < count else {
                return nil
            }

            var index = startIndex
            while index + holdCount < count {
                let windowSettled = (index..<(index + holdCount)).allSatisfy { abs(estimates[$0] - targets[$0]) <= band }
                if windowSettled {
                    return index
                }
                index += 1
            }

            return nil
        }
    }
}
