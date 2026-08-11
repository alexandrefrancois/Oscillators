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

import Foundation

internal struct ComplexRotation {
    var c: Float
    var s: Float

    static let identity = ComplexRotation(c: 1.0, s: 0.0)

    var magnitudeSquared: Float {
        c * c + s * s
    }

    var conjugate: ComplexRotation {
        ComplexRotation(c: c, s: -s)
    }

    func multiplied(by other: ComplexRotation) -> ComplexRotation {
        ComplexRotation(
            c: c * other.c - s * other.s,
            s: c * other.s + s * other.c
        )
    }

    func normalized(epsilon: Float = 1e-20) -> ComplexRotation {
        let magSquared = magnitudeSquared
        guard magSquared > epsilon, magSquared.isFinite else {
            return .identity
        }
        let inverseMagnitude = 1.0 / sqrt(magSquared)
        return ComplexRotation(c: c * inverseMagnitude, s: s * inverseMagnitude)
    }
    
    /// Normalize using the Taylor expansion around 1 for inverse square root.
    func normalizedTaylor(epsilon: Float = 1e-20) -> ComplexRotation {
        let magSquared = magnitudeSquared
        guard magSquared > epsilon, magSquared.isFinite else {
            return .identity
        }
        // Taylor expansion around 1 for 1/sqrt
        let inverseMagnitude = (Float(3.0) - magSquared) / Float(2.0)
        return ComplexRotation(c: c * inverseMagnitude, s: s * inverseMagnitude)
    }

    static func chordCorrection(
        dpc: Float,
        dps: Float,
        gamma: Float,
        epsilon: Float = 1e-20
    ) -> ComplexRotation? {
        let residualMagnitudeSquared = dpc * dpc + dps * dps
        guard residualMagnitudeSquared > epsilon, residualMagnitudeSquared.isFinite else {
            return nil
        }
        let inverseResidualMagnitude = 1.0 / sqrt(residualMagnitudeSquared)
        let uc = dpc * inverseResidualMagnitude
        let us = dps * inverseResidualMagnitude
        let correction = ComplexRotation(
            c: (1.0 - gamma) + gamma * uc,
            s: -gamma * us
        )
        return correction.normalized(epsilon: epsilon)
    }

    static func tangentCorrection(
        dpc: Float,
        dps: Float,
        gamma: Float,
        epsilon: Float = 1e-20
    ) -> ComplexRotation? {
        let residualMagnitudeSquared = dpc * dpc + dps * dps
        guard residualMagnitudeSquared > epsilon, residualMagnitudeSquared.isFinite else {
            return nil
        }
        let inverseResidualMagnitude = 1.0 / sqrt(residualMagnitudeSquared)
        let error = dps * inverseResidualMagnitude
        let correction = ComplexRotation(c: 1.0, s: -gamma * error)
        return correction.normalized(epsilon: epsilon)
    }
}
