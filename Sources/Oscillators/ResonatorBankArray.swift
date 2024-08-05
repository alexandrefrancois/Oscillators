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

fileprivate let numTasks = 6

/// An array of independent resonator instances
public class ResonatorBankArray {
    public private(set) var resonators = [Resonator]()
    public var numResonators: Int {
        resonators.count
    }
    public private(set) var amplitudes: [Float]

    public init(frequencies: [Float], sampleRate: Float, alpha: Float) {
        // initialize from passed frequencies
        amplitudes = [Float](repeating: 0, count: frequencies.count)
        
//        print("Number of resonators to create: \(targetFrequencies.count)")
        
        // setup an oscillator for each frequency
        for frequency in frequencies {
            resonators.append(Resonator(frequency: frequency, sampleRate: sampleRate, alpha: alpha))
        }
    }
    
    public init(alphas: [Float], sampleRate: Float, frequency: Float) {
        // initialize from passed frequencies
        amplitudes = [Float](repeating: 0, count: alphas.count)
        
//        print("Number of resonators to create: \(alphas.count)")
        
        // setup an oscillator for each alpha
        for alpha in alphas {
            resonators.append(Resonator(frequency: frequency, sampleRate: sampleRate, alpha: alpha))
        }
    }

    public func setAllAlphas(_ alpha: Float) {
        for resonator in resonators {
            resonator.alpha = alpha
        }
    }
        
    public func update(sample: Float) {
        for resonator in resonators {
            resonator.update(sample: sample)
        }
    }
    
    /// Sequentially update all resonators
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for (index, resonator) in resonators.enumerated() {
            resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
            self.amplitudes[index] = resonator.amplitude
        }
    }
    
    /// Concurrently update all resonators
    public func updateConcurrent(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await withTaskGroup(of: [(Int, Float)].self) { group in
                let resonatorStride = numTasks;
                for offset in 0..<resonatorStride {
                    group.addTask(priority: .high) {
                        var retVal = [(Int, Float)]()
                        var index = offset
                        while index < self.resonators.count {
                            self.resonators[index].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                            retVal.append((index, self.resonators[index].amplitude))
                            index += resonatorStride
                        }
                        return retVal
                    }
                }
                // collect all results when ready
                for await tuples in group {
                    for tuple in tuples {
                        self.amplitudes[tuple.0] = tuple.1
                    }
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}
