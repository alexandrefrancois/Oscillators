/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

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
/// Incremental calculations depend on sampling rate.
public class Oscillator : OscillatorProtocol {
    public private(set) var frequency: Float
    public var amplitude: Float = 0.0
    public private(set) var sampleRate: Float

    // Phasor
    internal var Wc: Float = 1.0
    internal var Ws: Float = 0.0
    internal var Oc: Float = 0.0
    internal var Os: Float = 0.0
    internal var Ocs: Float = 0.0
        
    init(frequency: Float, sampleRate: Float) {
        self.sampleRate = sampleRate
        self.frequency = frequency
        let omega = twoPi * frequency / sampleRate
        Oc = cos(omega)
        Os = sin(omega)
        Ocs = Oc + Os
        
        print("Oscillator init: ", frequency, "Hz / ", sampleRate, "Hz | ", Oc, Os)
    }

    // Basic 1 position increment
    internal func incrementPhase() {
        // complex multiplication with 3 real multiplications
        let ac = Oc*Wc
        let bd = Os*Ws
        let abcd = (Ocs) * (Wc+Ws)
        Wc = ac - bd
        Ws = abcd - ac - bd
    }
    
    // Stabilize
    internal func stabilize() {
        let k = (3.0 - Wc*Wc - Ws*Ws) / 2.0
        Wc *= k
        Ws *= k
    }
    
    // TODO: support change frequency, increment more than 1 sample position, etc.
}
