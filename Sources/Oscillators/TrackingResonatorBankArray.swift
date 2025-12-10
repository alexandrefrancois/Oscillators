/**
MIT License

Copyright (c) 2022-2025 Alexandre R. J. Francois

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

fileprivate let numTasks = 6

/// An array of independent resonator instances
public class TrackingResonatorBankArray {
    public static func alphasHeuristic(frequencies: [Float], sampleRate: Float, k: Float = 1, n: Float = 1) -> [Float] {
        frequencies.map { frequency in
            Resonator.alphaHeuristic(frequency: frequency, sampleRate: sampleRate, k: k, n: n)
        }
    }

    public private(set) var resonators = [TrackingResonator]()
    public var numResonators: Int {
        resonators.count
    }
    public var powers: [Float] {
        resonators.map { $0.power }
    }
    public var amplitudes: [Float] {
        resonators.map { $0.amplitude }
    }

    public init(frequencies: [Float], alphas: [Float], betas: [Float], sampleRate: Float) {
        assert(frequencies.count == alphas.count)
        // setup an oscillator for each frequency
        for (idx, frequency) in frequencies.enumerated() {
            resonators.append(TrackingResonator(frequency: frequency, alpha: alphas[idx], beta: betas[idx], sampleRate: sampleRate))
        }
    }
    
    /// A constructor that takes a function of frequency and sample rate to compute alphas
    public init(frequencies: [Float], sampleRate: Float, k: Float = 1.0, alphaHeuristic: (Float, Float, Float) -> Float) {
        // setup an oscillator for each frequency
        for frequency in frequencies {
            resonators.append(TrackingResonator(frequency: frequency, alpha: alphaHeuristic(frequency, sampleRate, k), sampleRate: sampleRate))
        }
    }
    
    public init(alphas: [Float], sampleRate: Float, frequency: Float) {
        // setup an oscillator for each alpha
        for alpha in alphas {
            resonators.append(TrackingResonator(frequency: frequency, alpha: alpha, sampleRate: sampleRate))
        }
    }
        
    public func update(sample: Float) {
        for resonator in resonators {
            resonator.update(sample: sample)
        }
    }
    
    /// Sequentially update all resonators
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for resonator in resonators {
            resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
        }
    }
    
    /// Concurrently update all resonators
    public func updateConcurrent(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await withTaskGroup(of: Int.self) { group in
                let resonatorStride = numTasks;
                for offset in 0..<resonatorStride {
                    group.addTask(priority: .high) {
                        var index = offset
                        while index < self.resonators.count {
                            self.resonators[index].updateAndTrack(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                            index += resonatorStride
                        }
                        return 0
                    }
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}
