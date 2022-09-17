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

/// An array of independent resonator instances
public class ResonatorBankArray {
    public private(set) var resonators = [Resonator]()
    public var numResonators: Int {
        resonators.count
    }
    public private(set) var maxima: [Float]

    public init(targetFrequencies: [Float], sampleDuration: Float, alpha: Float) {
        // initialize from passed frequencies
        maxima = [Float](repeating: 0, count: targetFrequencies.count)
        
//        print("Number of resonators to create: \(targetFrequencies.count)")
        
        // setup an oscillator for each frequency
        for frequency in targetFrequencies {
            resonators.append(Resonator(targetFrequency: frequency, sampleDuration: sampleDuration, alpha: alpha))
        }
    }
    
    public init(alphas: [Float], sampleDuration: Float, targetFrequency: Float) {
        // initialize from passed frequencies
        maxima = [Float](repeating: 0, count: alphas.count)
        
//        print("Number of resonators to create: \(alphas.count)")
        
        // setup an oscillator for each alpha
        for alpha in alphas {
            resonators.append(Resonator(targetFrequency: targetFrequency, sampleDuration: sampleDuration, alpha: alpha))
        }
    }

    public func setAllAlphas(_ alpha: Float) {
        for resonator in resonators {
            resonator.alpha = alpha
        }
    }
        
    public func update(sample: Float) {
        // this can be done in parallel?
        for resonator in resonators {
            resonator.update(sample: sample)
        }
    }
    
    public func updateSeq(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        for (index, resonator) in resonators.enumerated() {
            resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
            self.maxima[index] = resonator.amplitude
        }
    }
    
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await withTaskGroup(of: [(Int, Float)].self) { group in
                // make one single task with the top frequency oscillators as their runtime does not justify independent tasks
                let count2 = self.resonators.count/2
                group.addTask(priority: .high) {
                    var retVal = [(Int, Float)]()
                    for index in count2..<self.resonators.count {
                        self.resonators[index].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                        retVal.append((index, self.resonators[index].amplitude))
                    }
                    return retVal
                }
                // for the lower frequency oscillators
                // even out the task length by pairing resonators from both ends of the spectrum
                // taking into account that the complexity of the update is proportional to the size of the phases array
                for index in 0..<count2/2 {
                    let index2 = count2 - 1 - index
                    group.addTask(priority: .high) {
                        self.resonators[index].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                        self.resonators[index2].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                        return [(index, self.resonators[index].amplitude), (index2, self.resonators[index2].amplitude)]
                    }
                }
                if (count2 & 1) == 1 {
                    let index = count2 / 2
                    group.addTask(priority: .high) {
                        self.resonators[index].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                        return [(index, self.resonators[index].amplitude)]
                    }
                }
                // collect all results when ready
                for await tuples in group {
                    for tuple in tuples {
                        self.maxima[tuple.0] = tuple.1
                    }
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}
