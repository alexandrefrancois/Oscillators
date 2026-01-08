/**
MIT License

Copyright (c) 2025-2026 Alexandre R. J. Francois

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
import Atomics

/// An array of independent resonator instances
public class TrackingResonatorBankArray {
    public static func gammasHeuristic(frequencies: [Float], sampleRate: Float, k: Float = 1, n: Float = 1) -> [Float] {
        frequencies.map { frequency in
            TrackingResonator.gammaHeuristic(frequency: frequency, sampleRate: sampleRate, k: k, n: n)
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
    
    // 1. Use UInt32 to store the bits of the Float
    private let _accPowerBits = ManagedAtomic<UInt32>(Float(0.0001).bitPattern)

    public var accPower: Float {
        // 2. Load as UInt32 and bit-cast back to Float
        Float(bitPattern: _accPowerBits.load(ordering: .relaxed))
    }
    
    public init(naturalFrequencies: [Float], alphas: [Float], betas: [Float], gammas: [Float], sampleRate: Float) {
        assert(naturalFrequencies.count == alphas.count)
        // setup an oscillator for each frequency
        for (idx, naturalFrequency) in naturalFrequencies.enumerated() {
            resonators.append(TrackingResonator(naturalFrequency: naturalFrequency, alpha: alphas[idx], beta: betas[idx], gamma: gammas[idx], sampleRate: sampleRate))
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
        // 1. Snapshot the current atomic power (Load bits -> Float)
        let currentAccPower = Float(bitPattern: _accPowerBits.load(ordering: .relaxed))
        
        var maxPower = Float(0.0)
        
        // 2. Sequential update of all resonators for a single sample
        for resonator in resonators {
            // Pass the snapshotted value to the update method
            resonator.update(sample: sample, maxPower: currentAccPower)
            
            let power = resonator.power
            if power > maxPower {
                maxPower = power
            }
        }
        
        // 3. Compute the exponential moving average update
        let nextAccPower = (omSigma * currentAccPower) + (sigma * maxPower)
        
        // 4. Update the atomic storage (Float -> Store bits)
        _accPowerBits.store(nextAccPower.bitPattern, ordering: .relaxed)
    }
    
    /// Sequentially update all resonators
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        // 1. Snapshot the current atomic power (Load bits -> Float)
        let currentAccPower = Float(bitPattern: _accPowerBits.load(ordering: .relaxed))
        
        var maxPower = Float(0.0)
        
        // 2. Process resonators sequentially
        for resonator in resonators {
            // Use the snapshotted value for the update
            resonator.update(
                frameData: frameData,
                frameLength: frameLength,
                sampleStride: sampleStride,
                maxPower: currentAccPower
            )
            
            let power = resonator.power
            if power > maxPower {
                maxPower = power
            }
        }
        
        // 3. Calculate the new accumulated power
        let nextAccPower = (omSigma * currentAccPower) + (sigma * maxPower)
        
        // 4. Update the atomic storage (Float -> Store bits)
        _accPowerBits.store(nextAccPower.bitPattern, ordering: .relaxed)
    }
    
    /// Concurrently update all resonators
    public func updateConcurrent(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
        let numResonators = resonators.count
        guard numResonators > 0 else { return }

        // 3. Load bits and convert to Float for calculation
        let currentAccPower = Float(bitPattern: _accPowerBits.load(ordering: .relaxed))
        
        let numChunks = 4
        var localMaxes = [Float](repeating: 0.0, count: numChunks)

        DispatchQueue.concurrentPerform(iterations: numChunks) { chunkIdx in
            var chunkMax: Float = 0.0
            
            let start = (chunkIdx * numResonators) / numChunks
            let end = (chunkIdx == numChunks - 1) ? numResonators : ((chunkIdx + 1) * numResonators) / numChunks
            
            for i in start..<end {
                resonators[i].update(
                    frameData: frameData,
                    frameLength: frameLength,
                    sampleStride: sampleStride,
                    maxPower: currentAccPower
                )
                chunkMax = max(chunkMax, resonators[i].power)
            }
            localMaxes[chunkIdx] = chunkMax
        }

        let globalMaxPower = localMaxes.max() ?? 0.0
        let nextAccPower = omSigma * currentAccPower + sigma * globalMaxPower
        
        // 4. Convert Float back to bits and store
        _accPowerBits.store(nextAccPower.bitPattern, ordering: .relaxed)
    }
    
    public func setTimeConstant(_ tau: Float = 1.0, frameLength: Int, sampleStride: Int, sampleRate: Float) {
        let frameDuration =  Float(frameLength / sampleStride) / sampleRate
        sigma = Float(1.0) - exp(-frameDuration / tau)
    }
}
