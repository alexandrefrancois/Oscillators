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

class SignalFixtures {
    // MARK: - Helper Functions for Test Inputs

    static func makeImpulse(count: Int) -> [Float] {
        var arr = [Float](repeating: 0, count: count)
        arr[0] = 1.0
        return arr
    }

    static func makeStep(count: Int, value: Float = 1.0) -> [Float] {
        return [Float](repeating: value, count: count)
    }

    static func makeSine(count: Int, freq: Float, sampleRate: Float, amplitude: Float = 1.0) -> [Float] {
        let twoPi = Float.pi * 2.0
        return (0..<count).map { i in amplitude * sin(twoPi * freq * Float(i) / (sampleRate * Float(count))) }
    }
}
