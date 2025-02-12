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

/// A class to manipulate and compute frequencies in the digital world
public struct Dynamics {
    
    /// Compute the time constant from alpha value for a given sample rate
    /// - parameter alpha: what it says
    /// - parameter sampleDuration: same
    /// - returns: the time constant value
    public static func timeConstant(alpha: Float, sampleRate: Float) -> Float {
        -Float(1.0) / (sampleRate * log(Float(1.0) - alpha))
    }
    
    /// Compute the alpha value from time constant value for a given sample rate
    /// - parameter time constant: what it says
    /// - parameter sampleDuration: same
    /// - returns: the alpha value
    public static func alpha(timeConstant: Float, sampleRate: Float) -> Float {
        Float(1.0) - exp( -Float(1.0) / (sampleRate * timeConstant))
    }
}
