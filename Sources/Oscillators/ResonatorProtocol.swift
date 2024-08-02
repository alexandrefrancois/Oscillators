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

/// An oscillator that resonates with a specific frequency if present in an input signal,
/// i.e. that naturally oscillates with greater amplitude at a given frequency, than at other frequencies.
public protocol ResonatorProtocol {
    var alpha : Float { get set }
    var timeConstant : Float { get }
    var frequency : Float { get }
    
    /// This function performs an update of the resonator amplitude from a single sample
    func update(sample: Float)
    
    /// This function performs an update of the resonator amplitude from an array of samples
    func update(samples: [Float])
    
    /// This function performs an update of the resonator amplitude from a buffer of samples
    func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int)

    /// This function performs an update of the resonator amplitude from a single sample
    func updateAndTrack(sample: Float)
    
    /// This function performs an update of the resonator amplitude from an array of samples
    func updateAndTrack(samples: [Float])
    
    /// This function performs an update of the resonator amplitude from a buffer of samples
    func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int)

}
