/**
MIT License

Copyright (c) 2025 Alexandre R. J. Francois

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
    public var naturalFrequencies: [Float] {
        resonators.map { $0.naturalFrequency }
    }
    public var resonantFrequencies: [Float] {
        resonators.map { $0.resonantFrequency }
    }
    
    // max power accumulation
    private(set) var sigma: Float = 1.0 {
        didSet {
            omSigma = 1.0 - sigma
        }
    }
    private(set) var omSigma : Float = 0.0
    public private(set) var accPower: Float = 0.000000001
    
    public init(frequencies: [Float], alphas: [Float], betas: [Float], gammas: [Float], sampleRate: Float) {
        assert(frequencies.count == alphas.count)
        // setup an oscillator for each frequency
        for (idx, frequency) in frequencies.enumerated() {
            resonators.append(TrackingResonator(naturalFrequency: frequency, alpha: alphas[idx], beta: betas[idx], gamma: gammas[idx], sampleRate: sampleRate))
        }
    }
    
    /// A constructor that takes a function of frequency and sample rate to compute alphas
    public init(frequencies: [Float], sampleRate: Float, k: Float = 1.0, alphaHeuristic: (Float, Float, Float) -> Float) {
        // setup an oscillator for each frequency
        for frequency in frequencies {
            resonators.append(TrackingResonator(naturalFrequency: frequency, alpha: alphaHeuristic(frequency, sampleRate, k), sampleRate: sampleRate))
        }
    }
    
    public init(alphas: [Float], sigma: Float, sampleRate: Float, frequency: Float) {
        // setup an oscillator for each alpha
        for alpha in alphas {
            resonators.append(TrackingResonator(naturalFrequency: frequency, alpha: alpha, sampleRate: sampleRate))
        }
    }
        
    public func update(sample: Float) {
        var maxPower = Float(0.0)
        for resonator in resonators {
            resonator.update(sample: sample, maxPower: self.accPower)
            if resonator.power > maxPower {
                maxPower = resonator.power
            }
        }
        // update accPower
        accPower = omSigma * accPower + sigma * maxPower
    }
    
    /// Sequentially update all resonators
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        var maxPower = Float(0.0)
        for resonator in resonators {
            resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride, maxPower: self.accPower)
            if resonator.power > maxPower {
                maxPower = resonator.power
            }
        }
        // update accPower
        accPower = omSigma * accPower + sigma * maxPower
    }
    
    /// Concurrently update all resonators
    public func updateConcurrent(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            let maxPower = await withTaskGroup(of: Float.self) { group in
                let resonatorStride = numTasks;
                for offset in 0..<resonatorStride {
                    group.addTask(priority: .high) {
                        var maxPower = Float(0.0)
                        var index = offset
                        while index < self.resonators.count {
                            self.resonators[index].update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride, maxPower: self.accPower)
                            let power = self.resonators[index].power
                            if power > maxPower {
                                maxPower = power
                            }
                            index += resonatorStride
                        }
                        return maxPower
                    }
                }
                return await group
                    .compactMap { $0 }
                    .max() ?? 0.0
            }
            // update accPower
            accPower = omSigma * accPower + sigma * maxPower
            semaphore.signal()
        }
        semaphore.wait()
        
    }
    
    public func setTimeConstant(_ tau: Float = 1.0, frameLength: Int, sampleStride: Int, sampleRate: Float) {
        let frameDuration =  Float(frameLength / sampleStride) / sampleRate
        sigma = Float(1.0) - exp(-frameDuration / tau)
    }
}
