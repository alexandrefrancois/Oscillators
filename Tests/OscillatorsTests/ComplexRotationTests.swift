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

final class ComplexRotationTests: XCTestCase {
    private let epsilon: Float = 1e-6

    func testIdentityMultiplication() {
        let rotation = ComplexRotation(c: 0.25, s: -0.75)
        let product = rotation.multiplied(by: .identity)

        XCTAssertEqual(product.c, rotation.c, accuracy: epsilon)
        XCTAssertEqual(product.s, rotation.s, accuracy: epsilon)
    }

    func testConjugationProducesRealMagnitude() {
        let rotation = ComplexRotation(c: 0.6, s: 0.8)
        let product = rotation.multiplied(by: rotation.conjugate)

        XCTAssertEqual(product.c, rotation.magnitudeSquared, accuracy: epsilon)
        XCTAssertEqual(product.s, 0.0, accuracy: epsilon)
    }

    func testNormalization() {
        let rotations = [
            ComplexRotation(c: 3.0, s: 4.0),
            ComplexRotation(c: -7.0, s: 2.0),
            ComplexRotation(c: 0.125, s: -0.5)
        ]

        for rotation in rotations {
            XCTAssertEqual(rotation.normalized().magnitudeSquared, 1.0, accuracy: epsilon)
        }
    }

    func testNearZeroNormalizationReturnsFiniteIdentity() {
        let normalized = ComplexRotation(c: 1e-12, s: -1e-12).normalized(epsilon: 1e-20)

        XCTAssertTrue(normalized.c.isFinite)
        XCTAssertTrue(normalized.s.isFinite)
        XCTAssertEqual(normalized.c, 1.0, accuracy: epsilon)
        XCTAssertEqual(normalized.s, 0.0, accuracy: epsilon)
    }

    func testChordCorrectionGammaZeroIsIdentity() throws {
        let correction = try XCTUnwrap(ComplexRotation.chordCorrection(dpc: 0.3, dps: 0.7, gamma: 0.0))

        XCTAssertEqual(correction.c, 1.0, accuracy: epsilon)
        XCTAssertEqual(correction.s, 0.0, accuracy: epsilon)
    }

    func testChordCorrectionGammaOneIsConjugateResidual() throws {
        let residual = ComplexRotation(c: 0.3, s: 0.7).normalized()
        let correction = try XCTUnwrap(ComplexRotation.chordCorrection(dpc: residual.c, dps: residual.s, gamma: 1.0))

        XCTAssertEqual(correction.c, residual.conjugate.c, accuracy: epsilon)
        XCTAssertEqual(correction.s, residual.conjugate.s, accuracy: epsilon)
    }

    func testChordCorrectionHalfAngle() throws {
        for delta in [Float(-1.0), -0.25, 0.25, 1.0] {
            let correction = try XCTUnwrap(ComplexRotation.chordCorrection(
                dpc: cos(delta),
                dps: sin(delta),
                gamma: 0.5
            ))

            XCTAssertEqual(correction.c, cos(-0.5 * delta), accuracy: epsilon)
            XCTAssertEqual(correction.s, sin(-0.5 * delta), accuracy: epsilon)
        }
    }

    func testChordCorrectionSmallAngleEquivalence() throws {
        for delta in [Float(-0.05), -0.01, -0.001, 0.001, 0.01, 0.05] {
            let gamma = Float(0.4)
            let correction = try XCTUnwrap(ComplexRotation.chordCorrection(
                dpc: cos(delta),
                dps: sin(delta),
                gamma: gamma
            ))

            XCTAssertEqual(correction.c, cos(-gamma * delta), accuracy: 2e-4)
            XCTAssertEqual(correction.s, sin(-gamma * delta), accuracy: 2e-4)
        }
    }

    func testTangentCorrectionSign() throws {
        let positive = try XCTUnwrap(ComplexRotation.tangentCorrection(dpc: 1.0, dps: 0.1, gamma: 0.5))
        let negative = try XCTUnwrap(ComplexRotation.tangentCorrection(dpc: 1.0, dps: -0.1, gamma: 0.5))

        XCTAssertLessThan(positive.s, 0.0)
        XCTAssertGreaterThan(negative.s, 0.0)
    }

    func testTangentCorrectionSmallAngleEquivalence() throws {
        for delta in [Float(-0.05), -0.01, -0.001, 0.001, 0.01, 0.05] {
            let gamma = Float(0.4)
            let correction = try XCTUnwrap(ComplexRotation.tangentCorrection(
                dpc: cos(delta),
                dps: sin(delta),
                gamma: gamma
            ))

            XCTAssertEqual(correction.c, cos(-gamma * delta), accuracy: 7e-4)
            XCTAssertEqual(correction.s, sin(-gamma * delta), accuracy: 7e-4)
        }
    }

    func testChordCorrectionRepeatedNormalizationDoesNotDrift() throws {
        let drift = try repeatedCorrectionDrift { dpc, dps, gamma in
            try XCTUnwrap(ComplexRotation.chordCorrection(dpc: dpc, dps: dps, gamma: gamma))
        }

        XCTAssertLessThanOrEqual(drift, 2e-5)
    }

    func testTangentCorrectionRepeatedNormalizationDoesNotDrift() throws {
        let drift = try repeatedCorrectionDrift { dpc, dps, gamma in
            try XCTUnwrap(ComplexRotation.tangentCorrection(dpc: dpc, dps: dps, gamma: gamma))
        }

        XCTAssertLessThanOrEqual(drift, 2e-5)
    }

    private func repeatedCorrectionDrift(
        correction: (Float, Float, Float) throws -> ComplexRotation,
        normalize: (ComplexRotation) -> ComplexRotation = { $0.normalized() }
    ) throws -> Float {
        var rotation = ComplexRotation.identity
        var maximumDrift: Float = 0.0

        for index in 0..<20_000 {
            let delta = Float(index % 101 - 50) * 0.001
            let scale = residualScale(at: index)
            let gamma = Float(0.35)
            let nextCorrection = try correction(scale * cos(delta), scale * sin(delta), gamma)
            rotation = normalize(rotation.multiplied(by: nextCorrection))
            maximumDrift = max(maximumDrift, abs(rotation.magnitudeSquared - 1.0))
        }

        return maximumDrift
    }

    private func residualScale(at index: Int) -> Float {
        let scales: [Float] = [0.2, 0.5, 0.8, 1.0, 1.25, 1.5, 2.0]
        return scales[index % scales.count]
    }
}
