//
//  PhasorDouble.swift
//  Oscillators
//
//  Created by Alexandre Francois on 01/08/2026.
//

import Foundation

fileprivate let twoPi = Double.pi * 2.0

/// PhasorDouble class:
/// A complex phasor allows to compute sinusoid values recursively.
/// Incremental calculations depend on frequency and sampling rate.
/// This is the base class for individual oscillators and resonators.
open class PhasorDouble {
    public var frequency: Double {
        get {
            -omega * sampleRateOverTwoPi
        }
        set {
            omega = -newValue / sampleRateOverTwoPi
            updateMultiplier()
        }
    }
    
    public var sampleRate: Double {
        didSet {
            sampleRateOverTwoPi = sampleRate / twoPi
            updateMultiplier()
        }
    }
    
    /// Angular velocity
    /// omega = -2 pi frequency / sample rate
    public var omega: Double { // this is the angular velocity,
        didSet {
            updateMultiplier()
        }
    }
    internal var sampleRateOverTwoPi: Double // this is the angular velocity,

    public var magnitudeSq: Double {
        Zc*Zc + Zs*Zs
    }
    
    public var magnitude: Double {
        sqrt(Zc*Zc + Zs*Zs)
    }

    // Phasor variables
    // Phasor: Z = Zc + i Zs
    // Multiplier: W = Wc + i Ws
    internal var Zc : Double = 1.0
    internal var Zs : Double = 0.0
    internal var Wc : Double = 0.0
    internal var Ws : Double = 0.0
    internal var Wcps : Double = 0.0 // pre-computed Oc + Os

    private var stabilizeCounter: Int = 0
    
    
    init(omega: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.sampleRateOverTwoPi = sampleRate / twoPi
        self.omega = omega
        updateMultiplier()
    }

    init(frequency: Double, sampleRate: Double) {
        self.sampleRate = sampleRate
        self.sampleRateOverTwoPi = sampleRate / twoPi
        self.omega = -frequency / self.sampleRateOverTwoPi
        updateMultiplier()
    }

    func updateMultiplier() {
        Wc = cos(omega)
        Ws = sin(omega)
        Wcps = Wc + Ws
    }
        
    /// Compute next value of the phasor
    /// Z <- Z * W
    internal func incrementPhase() {
        // complex multiplication with 3 real multiplications
        let ac = Wc*Zc
        let bd = Ws*Zs
        let abcd = (Wcps) * (Zc+Zs)
        Zc = ac - bd
        Zs = abcd - ac - bd
    }
    
    /// Apply re-normalization correction to compensate for
    /// numerical drift, use Taylor expansion around 1 to approximate
    /// 1/sqrt(x) to reduce computational cost.
    /// This can be applied every few hundred (?) samples
    internal func stabilize() {
        let k = (Double(3.0) - Zc*Zc - Zs*Zs) / Double(2.0)
        Zc *= k
        Zs *= k
    }
    
    internal func stabilizeIfNeeded() -> Int {
        let errorSquare = abs(Double(1.0) - Zc*Zc + Zs*Zs)
        stabilizeCounter = stabilizeCounter + 1
        if errorSquare > 1e-5 {
            stabilize()
            stabilizeCounter = 0
        }
        return stabilizeCounter
    }
}
