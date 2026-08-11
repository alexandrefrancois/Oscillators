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
public final class ImplicitTrackingResonator: Phasor, TrackingResonatorProtocol {
    public static func gammaHeuristic(frequency: Float, sampleRate: Float, k: Float = 1, n: Float = 1) -> Float {
        TrackingResonator.gammaHeuristic(frequency: frequency, sampleRate: sampleRate, k: k, n: n)
    }

    public let trackingRule: ImplicitTrackingRule

    public var power: Float {
        cc * cc + ss * ss
    }

    public var amplitude: Float {
        sqrt(power)
    }

    public var phase: Float {
        atan2(ss, cc)
    }

    public var phaseComps: (cos: Float, sin: Float) {
        let mag = sqrt(power)
        return (cc / mag, ss / mag)
    }

    public var deltaPhase: Float {
        atan2(dps, dpc)
    }

    public var deltaPhaseComps: (cos: Float, sin: Float) {
        let mag = sqrt(dps * dps + dpc * dpc)
        return (dpc / mag, dps / mag)
    }

    public var alpha: Float {
        didSet {
            omAlpha = 1.0 - alpha
        }
    }
    private(set) var omAlpha: Float = 0.0

    public var beta: Float {
        didSet {
            omBeta = 1.0 - beta
        }
    }
    private(set) var omBeta: Float = 0.0

    public var gamma: Float {
        didSet {
            omGamma = 1.0 - gamma
        }
    }
    private(set) var omGamma: Float = 0.0

    private(set) var trackFrequencyPowerThreshold = Float(0.001)

    private(set) var c: Float = 0.0
    private(set) var s: Float = 0.0

    public private(set) var cc: Float = 0.0
    public private(set) var ss: Float = 0.0

    public private(set) var dpc: Float = 1.0
    public private(set) var dps: Float = 0.0

    public var resonantFrequency: Float {
        frequency
    }

    public private(set) var naturalFrequency: Float

    private var naturalWc: Float
    private var naturalWs: Float

    public func setNaturalFrequency(_ naturalFrequency: Float, alpha: Float, beta: Float? = nil, gamma: Float? = nil) {
        self.naturalFrequency = naturalFrequency
        self.alpha = alpha
        self.beta = beta ?? alpha
        self.gamma = gamma ?? alpha

        let naturalOmega = -naturalFrequency / sampleRateOverTwoPi
        naturalWc = cos(naturalOmega)
        naturalWs = sin(naturalOmega)
        setMultiplier(c: naturalWc, s: naturalWs)
    }

    public init(
        naturalFrequency: Float,
        alpha: Float,
        beta: Float? = nil,
        gamma: Float? = nil,
        sampleRate: Float,
        trackingRule: ImplicitTrackingRule
    ) {
        self.naturalFrequency = naturalFrequency
        self.alpha = alpha
        self.omAlpha = 1.0 - alpha
        self.beta = beta ?? alpha
        self.omBeta = 1.0 - self.beta
        self.gamma = gamma ?? alpha
        self.omGamma = 1.0 - self.gamma
        self.trackingRule = trackingRule
        let naturalOmega = -naturalFrequency / (sampleRate / twoPi)
        self.naturalWc = cos(naturalOmega)
        self.naturalWs = sin(naturalOmega)
        super.init(frequency: naturalFrequency, sampleRate: sampleRate)
    }

    func updateWithSample(_ sample: Float) {
        let alphaSample: Float = alpha * sample
        c = omAlpha * c + alphaSample * Zc
        s = omAlpha * s + alphaSample * Zs

        let lcc = cc
        let lss = ss

        cc = omBeta * cc + beta * c
        ss = omBeta * ss + beta * s

        dpc = cc * lcc + ss * lss
        dps = ss * lcc - cc * lss

        if power > trackFrequencyPowerThreshold {
            applyImplicitCorrection()
        } else {
            restoreNaturalMultiplier()
        }

        incrementPhase()
    }

    public func update(sample: Float, maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(implicitMinMaxPower, maxPower) / Float(1000.0)
        updateWithSample(sample)
        stabilize()
    }

    public func update(samples: [Float], maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(implicitMinMaxPower, maxPower) / Float(1000.0)
        for sample in samples {
            updateWithSample(sample)
        }
        stabilize()
    }

    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int, maxPower: Float = 0.25) {
        trackFrequencyPowerThreshold = max(implicitMinMaxPower, maxPower) / Float(1000.0)
        for sampleIndex in stride(from: 0, to: sampleStride * frameLength, by: sampleStride) {
            updateWithSample(frameData[sampleIndex])
        }
        stabilize()
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
        let next = current.multiplied(by: correction).normalized(epsilon: minimumResidualMagnitudeSquared)
        setMultiplier(c: next.c, s: next.s)
    }

    private func restoreNaturalMultiplier() {
        setMultiplier(c: naturalWc, s: naturalWs)
    }
}
