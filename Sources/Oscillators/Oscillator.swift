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

import Foundation

fileprivate let twoPi = Float.pi * 2.0

/// Oscillator base class:
/// an oscillator is characterized by its frequency and amplitude.
/// Waveform values are computed recursively with a complex phasor.
/// Incremental calculations depend on frequency and sampling rate.
public class Oscillator : OscillatorProtocol {
    public var frequency: Float {
        didSet {
            updateMultiplier()
        }
    }
    public var sampleRate: Float {
        didSet {
            updateMultiplier()
        }
    }
    public var amplitude: Float = 1.0

    public var sample : Float {
        amplitude * Zc
    }
    
    // Phasor variables
    // Phasor: Z = Zc + i Zs
    // Multiplier: W = Wc + i Ws
    internal var Zc : Float = 1.0
    internal var Zs : Float = 0.0
    internal var Wc : Float = 0.0
    internal var Ws : Float = 0.0
    internal var Wcps : Float = 0.0 // pre-computed Oc + Os
    
    init(frequency: Float, sampleRate: Float) {
        self.sampleRate = sampleRate
        self.frequency = frequency
        updateMultiplier()
    }

    func updateMultiplier() {
        let omega = twoPi * frequency / sampleRate
        Wc = cos(omega)
        Ws = sin(omega)
        Wcps = Wc + Ws
    }
    
    /// Compute next value of the phasor
    /// Z <- Z * W
    internal func incrementPhase() {
        // W <- W * O
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
        let k = (3.0 - Zc*Zc - Zs*Zs) / 2.0
        Zc *= k
        Zs *= k
    }
    
}
