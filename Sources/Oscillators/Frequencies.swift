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

/// Speed of sound at room temperature, in m/s
fileprivate let speedOfSound: Float = 346.0

/// A class to manipulate and compute frequencies in the digital world
public struct Frequencies {
    
    /// Compute and return an array of equal temperament picth frequencies
    /// between (and including) the notes at the 2 indices provided.
    /// In equal temperament, an interval of 1 semitone has a frequency ratio of 2^(1/12) (approx. 1.05946)
    /// the tuning is set for A4 which, if index 0 denotes C0, is index 57.
    /// Typical piano range from A0=9 (27.500 Hz) to C8=96 (4186.009 Hz)
    public static func musicalPitchFrequencies(from: Int, to: Int, tuning: Float = 440.0) -> [Float] {
        return (from...to).map { idx in
            tuning * powf(2.0, Float(idx - 57) / 12.0)
        }
    }
    
    /// Compute and return an array of frequencies of the provided size,
    /// in which the frequencies follow a log uniform distribution
    /// between (and including) the start and end frequencies.
    public static func logUniformFrequencies(fMin: Float = 32.70, numBins: Int = 84, numBinsPerOctave: Int = 12) -> [Float] {
        return (0..<numBins).map { bin in
            fMin * powf(2.0, Float(bin) / Float(numBinsPerOctave))
        }
    }
    
    /// Compute the Doppler velocity from an observed and source frequency.
    /// - parameter observedFrequency: the frequency measured by the observer
    /// - parameter referenceFrequency: the frequency of the sound emitted by the source
    /// - returns: the relative velocity of the source to the receiver (positive when they are getting closer)
    public static func dopplerVelocity(observedFrequency: Float, referenceFrequency: Float) -> Float {
        guard referenceFrequency > 0 else { return 0 }
        return speedOfSound * (observedFrequency - referenceFrequency) / referenceFrequency
    }
    
    public static func alphaHeuristic(frequency: Float, sampleRate: Float) -> Float {
        return powf(10.0, -(5 - 0.8*log10(frequency))) * (44100.0 / sampleRate)
    }
}
