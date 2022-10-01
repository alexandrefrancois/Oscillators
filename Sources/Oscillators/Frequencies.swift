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

/// Speed of sound at room temperature, in m/s
fileprivate let speedOfSound: Float = 346.0

/// A class to manipulate and compute frequencies in the digital world
public struct Frequencies {
    
    /// Compute the closest frequency to the target frequency that corresponds to a wavelength which is an integer number of samples
    /// - parameter targetFrequency: what it says
    /// - parameter sampleDuration: same
    /// - returns: the frequency
    public static func closestFrequency(targetFrequency: Float, sampleDuration: Float) -> Float {
        let maxNumSamplesInPeriod = (1.0 / (sampleDuration * targetFrequency)).rounded()
        let frequency = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
        return frequency
    }
    
    /// Compute the Doppler velocity from an observed and source frequency.
    /// - parameter observedFrequency: the frequency measured by the observer
    /// - parameter referenceFrequency: the frequency of the sound emitted by the source
    /// - returns: the relative velocity of the source to the receiver (positive when they are getting closer)
    public static func dopplerVelocity(observedFrequency: Float, referenceFrequency: Float) -> Float {
        guard referenceFrequency > 0 else { return 0 }
        return speedOfSound * (observedFrequency - referenceFrequency) / referenceFrequency
    }    
}
