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

fileprivate let twoPi = Float.pi * 2.0
fileprivate let implicitMinMaxPower = Float(0.001)
fileprivate let minimumResidualMagnitudeSquared = Float(1e-20)

public enum ImplicitTrackingRule: Equatable, CaseIterable, CustomStringConvertible {
    case normalizedChord
    case tangent
    
    public var description: String {
        switch self {
        case .normalizedChord:
            return "Chord"
        case .tangent:
            return "Tangent"
        }
    }
}

/// The resonant frequency is represented implicitly by the phasor multiplier W.
/// Tracking modifies W directly from the residual complex phase rotation of the
/// Resonate response. No phase angle or numerical frequency is computed in the
/// adaptation loop. Numerical frequency is recovered with atan2 only when
/// explicitly requested as a readout.
public final class ImplicitTrackingResonator: TrackingResonator {
    public let trackingRule: ImplicitTrackingRule
    
    public init(
        naturalFrequency: Float,
        alpha: Float,
        beta: Float? = nil,
        gamma: Float? = nil,
        sampleRate: Float,
        trackingRule: ImplicitTrackingRule
    ) {
        self.trackingRule = trackingRule
        super.init(naturalFrequency: naturalFrequency, alpha: alpha, beta: beta, gamma: gamma, sampleRate: sampleRate)
    }
    
    override func updateTracking() {
        if power > trackFrequencyPowerThreshold {
            applyImplicitCorrection()
        } else {
            restoreNaturalW()
        }
    }
        
    private func applyImplicitCorrection() {
        let correction: ComplexRotation?
        switch trackingRule {
        case .normalizedChord:
            // Normalized interpolation on the unit circle between identity and the
            // conjugate residual rotation. Near lock it is first-order equivalent
            // to applying omega -= gamma * deltaPhase.
            correction = ComplexRotation.chordCorrection(
                dpc: dpc,
                dps: dps,
                gamma: gamma,
                epsilon: minimumResidualMagnitudeSquared
            )
        case .tangent:
            // Normalized residual quadrature is a signed local adaptation signal
            // that moves the phasor multiplier tangentially on the unit circle.
            correction = ComplexRotation.tangentCorrection(
                dpc: dpc,
                dps: dps,
                gamma: gamma,
                epsilon: minimumResidualMagnitudeSquared
            )
        }
        
        guard let correction else {
            return
        }
        
        let current = ComplexRotation(c: Wc, s: Ws)
        // Taylor expansion around 1 should be enough here
        let next = current.multiplied(by: correction).normalizedTaylor(epsilon: minimumResidualMagnitudeSquared)
        setW(c: next.c, s: next.s)
    }
}
