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
public class ResonatorBankArray {
    public static func alphasHeuristic(frequencies: [Float], sampleRate: Float, k: Float = 1) -> [Float] {
        frequencies.map { frequency in
            Resonator.alphaHeuristic(frequency: frequency, sampleRate: sampleRate, k: k)
        }
    }

    public private(set) var resonators = [Resonator]()
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
        // initialize from passed frequencies
//        powers = [Float](repeating: 0, count: frequencies.count)
//        amplitudes = [Float](repeating: 0, count: frequencies.count)
        // setup an oscillator for each frequency
        for (idx, frequency) in frequencies.enumerated() {
            resonators.append(Resonator(frequency: frequency, alpha: alphas[idx], beta: betas[idx], sampleRate: sampleRate))
        }
    }
    
    /// A constructor that takes a function of frequency and sample rate to compute alphas
    public init(frequencies: [Float], sampleRate: Float, k: Float = 1.0, alphaHeuristic: (Float, Float, Float) -> Float) {
        // initialize from passed frequencies
//        powers = [Float](repeating: 0, count: frequencies.count)
//        amplitudes = [Float](repeating: 0, count: frequencies.count)
        // setup an oscillator for each frequency
        for frequency in frequencies {
            resonators.append(Resonator(frequency: frequency, alpha: alphaHeuristic(frequency, sampleRate, k), sampleRate: sampleRate))
        }
    }
    
    public init(alphas: [Float], sampleRate: Float, frequency: Float) {
        // initialize from passed alphas
//        powers = [Float](repeating: 0, count: alphas.count)
//        amplitudes = [Float](repeating: 0, count: alphas.count)
        // setup an oscillator for each alpha
        for alpha in alphas {
            resonators.append(Resonator(frequency: frequency, alpha: alpha, sampleRate: sampleRate))
        }
    }
        
    public func update(sample: Float) {
        for (index, resonator) in resonators.enumerated() {
            resonator.update(sample: sample)
//            self.powers[index] = resonator.power
//            self.amplitudes[index] = resonator.amplitude
        }
    }
    
    /// Sequentially update all resonators
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for (index, resonator) in resonators.enumerated() {
            resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
//            self.powers[index] = resonator.power
//            self.amplitudes[index] = resonator.amplitude
        }
    }
    
    /// Concurrently update all resonators
    public func updateConcurrent(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
//            await withTaskGroup(of: [(Int, Float, Float)].self) { group in
            await withTaskGroup(of: Int.self) { group in
                let resonatorStride = numTasks;
                for offset in 0..<resonatorStride {
                    group.addTask(priority: .high) {
//                        var retVal = [(Int, Float, Float)]()
                        var index = offset
                        while index < self.resonators.count {
                            self.resonators[index].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
//                            retVal.append((index, self.resonators[index].power, self.resonators[index].amplitude))
                            index += resonatorStride
                        }
//                        return retVal
                        return 0
                    }
                }
                // collect all results when ready
//                for await tuples in group {
//                    for tuple in tuples {
//                        self.powers[tuple.0] = tuple.1
//                        self.amplitudes[tuple.0] = tuple.2
//                    }
//                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}
