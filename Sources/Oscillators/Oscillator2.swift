/**
MIT License

Copyright (c) 2023 Alexandre R. J. Francois

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
import Accelerate

/// Oscillator base class:
/// an oscillator is characterized by its frequency, amplitude and waveform
/// whose duration is an integer multiple of the sample duration
public class Oscillator2 : OscillatorProtocol {
    public private(set) var sampleDuration: Float
    public private(set) var frequency: Float
    
    public var amplitude: Float = 0.0
    
    internal var phaseIdx: Float = 0.0
    internal var phaseIncrement: Float
        
    init(frequency: Float, sampleDuration: Float) {
        self.frequency = frequency
        self.sampleDuration = sampleDuration
        
        phaseIncrement = SineLUT.phaseIncrement(frequency: frequency, samplingRate: 1.0 / sampleDuration)
    }
}