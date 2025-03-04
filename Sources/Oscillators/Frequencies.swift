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
import Accelerate

/// Speed of sound at room temperature, in m/s
fileprivate let speedOfSound: Float = 346.0

/// A class to manipulate and compute frequencies in the digital world
public struct Frequencies {
    
    /// Compute and return an array of equal temperament picth frequencies
    /// between (and including) the notes at the 2 indices provided.
    /// In equal temperament, an interval of 1 semitone has a frequency ratio of 2^(1/12) (approx. 1.05946)
    /// the tuning is set for A4 which, if index 0 denotes C0, is index 57.
    /// Typical piano range from A0=9 (27.500 Hz) to C8=96 (4186.009 Hz)
    public static func musicalPitchFrequencies(from: Int, to: Int, tuning: Float = 440.0) -> [Float] {
        return (from...to).map { idx in
            tuning * powf(2.0, Float(idx - 57) / 12.0)
        }
    }
    
    /// Compute and return an array of frequencies of the provided size,
    /// in which the frequencies follow a log uniform distribution
    /// between (and including) the start and end frequencies.
    public static func logUniformFrequencies(minFrequency: Float = 32.70, numBins: Int = 84, numBinsPerOctave: Int = 12) -> [Float] {
        return (0..<numBins).map { bin in
            minFrequency * powf(2.0, Float(bin) / Float(numBinsPerOctave))
        }
    }
}

extension Frequencies {
    // Mels
    
    /// Compute and return an array of acoustic frequencies tuned to the mel scale.
    /// Two implementations:
    /// Default: Slaney, M. Auditory Toolbox: A MATLAB Toolbox for Auditory Modeling Work. Technical Report, version 2, Interval Research Corporation, 1998.
    /// HTK: Young, S., Evermann, G., Gales, M., Hain, T., Kershaw, D., Liu, X., Moore, G., Odell, J., Ollason, D., Povey, D., Valtchev, V., & Woodland, P. The HTK book, version 3.4. Cambridge University, March 2009.
    ///
    ///n_mels=128, *, fmin=0.0, fmax=11025.0, htk=False)
    ///
    public static func melFrequencies(numMels: Int = 128, minFrequency: Float = 0.0, maxFrequency: Float = 11025.0, htk: Bool = false) -> [Float] {
        let minMel = htk ? hzToMelHTK(minFrequency): hzToMel(minFrequency)
        let maxMel = htk ? hzToMelHTK(maxFrequency): hzToMel(maxFrequency)
        let mels = Array(stride(from: minMel, through: maxMel, by: (maxMel - minMel) / Float(numMels - 1)))
        let frequencies = htk ? melsToHzHTK(mels) : melsToHz(mels)
        return frequencies
    }
    
    /// Convert Hz to Mels - Matlab Auditory Toolbox formula
    public static func hzToMel(_ frequency: Float) -> Float {
        let minFrequency: Float = 0.0
        let spFrequency: Float = 200.0 / 3
        let minLogFrequency: Float = 1000.0
        if frequency < minLogFrequency {
            // Linear range
            return (frequency - minFrequency) / spFrequency
        }
        // Log range
        let minLogMel = (minLogFrequency - minFrequency) / spFrequency
        let logstep: Float = log(6.4) / 27.0
        return minLogMel + log(frequency / minLogFrequency) / logstep
    }
    
    public static func hzToMel(_ frequencies: [Float]) -> [Float] {
        frequencies.map { frequency in
            hzToMel(frequency)
        }
    }
    
    /// Convert Hz to Mels - HTK formula
    public static func hzToMelHTK(_ frequency: Float) -> Float {
        return 2595.0 * log10(1.0 + frequency / 700.0)
    }
    
    public static func hzToMelHTK(_ frequency: [Float]) -> [Float] {
        return frequency.map { frequency in
            hzToMelHTK(frequency)
        }
    }
    
    /// Convert mel bin numbers to frequencies
    public static func melToHz(_ mel: Float) -> Float {
        let minFrequency: Float = 0.0
        let spFrequency: Float = 200.0 / 3
        let minLogFrequency: Float = 1000.0
        let minLogMel = (minLogFrequency - minFrequency) / spFrequency
        if mel < minLogMel {
            // Linear range
            return minFrequency + spFrequency * mel
        }
        // Log range
        let logstep: Float = log(6.4) / 27.0
        return minLogFrequency * exp(logstep * (mel - minLogMel))
    }
    
    public static func melsToHz(_ mels: [Float]) -> [Float] {
        return mels.map { mel in
            melToHz(mel)
        }
    }
    
    public static func melToHzHTK(_ mel: Float) -> Float {
        return 700.0 * (powf(10.0, (mel / 2595.0)) - 1.0)
    }
    
    public static func melsToHzHTK(_ mels: [Float]) -> [Float] {
        return mels.map { mel in
            melToHzHTK(mel)
        }
    }
}

extension Frequencies {
    
    /// Compute the Doppler velocity from an observed and source frequency.
    /// - parameter observedFrequency: the frequency measured by the observer
    /// - parameter referenceFrequency: the frequency of the sound emitted by the source
    /// - returns: the relative velocity of the source to the receiver (positive when they are getting closer)
    public static func dopplerVelocity(observedFrequency: Float, referenceFrequency: Float) -> Float {
        guard referenceFrequency > 0 else { return 0 }
        return speedOfSound * (observedFrequency - referenceFrequency) / referenceFrequency
    }
}

extension Frequencies {
    
    /// Compute the equalizer coefficients for given frequencies and alphas
    /// - parameter frequencies: the frequencies for the resonator bank
    /// - parameter alphas: alphas (accumulation) for the resonator bank
    /// - parameter betas: the betas (smoothing) for the resonator bank
    /// - returns: an array of coefficients (one per frequency)
    public static func frequencySweep(frequencies: [Float], alphas: [Float], betas: [Float]? = nil, sampleRate: Float) -> [Float] {
        var output = [Float](repeating: 0, count: frequencies.count)
        let bank = ResonatorBankVec(frequencies: frequencies, alphas: alphas, betas: betas ?? nil, sampleRate: sampleRate)
        for (idx, frequency) in frequencies.enumerated() {
            let oscillator = Oscillator(frequency: frequency, sampleRate: sampleRate)
            let duration = 10 * Dynamics.timeConstant(alpha: alphas[idx], sampleRate: sampleRate)
            let numSamples = Int(duration * sampleRate)
            let frame = oscillator.getNextSamples(numSamples: numSamples)
            bank.update(frame: frame)
            let powers = bank.powers
            output[idx] = 0.25 / sqrt(vDSP.sum(powers))
            bank.reset()
        }
        return output
    }
}
