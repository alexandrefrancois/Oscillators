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

struct TrackingSignalFixtures {
    struct FrequencyTrace {
        let samples: [Float]
        let frequencies: [Float]
    }

    static func constantTone(
        count: Int,
        frequency: Float,
        amplitude: Float = 1.0,
        sampleRate: Float,
        initialPhase: Float = 0.0
    ) -> FrequencyTrace {
        render(count: count, sampleRate: sampleRate, initialPhase: initialPhase) { _ in
            (frequency: frequency, amplitude: amplitude)
        }
    }

    static func frequencyStep(
        firstFrequency: Float,
        secondFrequency: Float,
        transitionIndex: Int,
        count: Int,
        amplitude: Float = 1.0,
        sampleRate: Float
    ) -> FrequencyTrace {
        render(count: count, sampleRate: sampleRate) { index in
            let frequency = index < transitionIndex ? firstFrequency : secondFrequency
            return (frequency: frequency, amplitude: amplitude)
        }
    }

    static func chirp(
        count: Int,
        startFrequency: Float,
        endFrequency: Float,
        amplitude: Float = 1.0,
        sampleRate: Float
    ) -> FrequencyTrace {
        let denominator = max(Float(count - 1), 1.0)
        return render(count: count, sampleRate: sampleRate) { index in
            let progress = Float(index) / denominator
            let frequency = startFrequency + progress * (endFrequency - startFrequency)
            return (frequency: frequency, amplitude: amplitude)
        }
    }

    static func vibrato(
        count: Int,
        carrierFrequency: Float,
        modulationRate: Float,
        deviation: Float,
        amplitude: Float = 1.0,
        sampleRate: Float
    ) -> FrequencyTrace {
        render(count: count, sampleRate: sampleRate) { index in
            let time = Float(index) / sampleRate
            let frequency = carrierFrequency + deviation * sin(2.0 * Float.pi * modulationRate * time)
            return (frequency: frequency, amplitude: amplitude)
        }
    }

    static func amplitudeDropout(
        count: Int,
        frequency: Float,
        amplitude: Float,
        dropoutRange: Range<Int>,
        sampleRate: Float
    ) -> FrequencyTrace {
        render(count: count, sampleRate: sampleRate) { index in
            let sampleAmplitude: Float = dropoutRange.contains(index) ? 0.0 : amplitude
            return (frequency: frequency, amplitude: sampleAmplitude)
        }
    }

    static func noisyTone(
        count: Int,
        frequency: Float,
        amplitude: Float,
        snrDecibels: Float,
        sampleRate: Float,
        seed: UInt64 = 0x1234abcd
    ) -> FrequencyTrace {
        let clean = constantTone(count: count, frequency: frequency, amplitude: amplitude, sampleRate: sampleRate)
        let signalPower = amplitude * amplitude / 2.0
        let noisePower = signalPower / pow(10.0, snrDecibels / 10.0)
        let noiseScale = sqrt(noisePower)
        var generator = SeededGenerator(state: seed)
        let noisy = clean.samples.map { sample in
            sample + noiseScale * generator.nextUnitFloat()
        }
        return FrequencyTrace(samples: noisy, frequencies: clean.frequencies)
    }

    static func twoTone(
        count: Int,
        firstFrequency: Float,
        secondFrequency: Float,
        firstAmplitude: Float,
        secondAmplitude: Float,
        sampleRate: Float
    ) -> [Float] {
        let first = constantTone(count: count, frequency: firstFrequency, amplitude: firstAmplitude, sampleRate: sampleRate)
        let second = constantTone(count: count, frequency: secondFrequency, amplitude: secondAmplitude, sampleRate: sampleRate)
        return zip(first.samples, second.samples).map(+)
    }

    private static func render(
        count: Int,
        sampleRate: Float,
        initialPhase: Float = 0.0,
        parametersAtIndex: (Int) -> (frequency: Float, amplitude: Float)
    ) -> FrequencyTrace {
        var samples = [Float]()
        var frequencies = [Float]()
        samples.reserveCapacity(count)
        frequencies.reserveCapacity(count)

        var phase = initialPhase
        for index in 0..<count {
            let parameters = parametersAtIndex(index)
            samples.append(parameters.amplitude * sin(phase))
            frequencies.append(parameters.frequency)
            phase += 2.0 * Float.pi * parameters.frequency / sampleRate
        }

        return FrequencyTrace(samples: samples, frequencies: frequencies)
    }

    private struct SeededGenerator {
        var state: UInt64

        mutating func nextUnitFloat() -> Float {
            state = 6364136223846793005 &* state &+ 1442695040888963407
            let value = Float((state >> 40) & 0xffffff) / Float(0xffffff)
            return 2.0 * value - 1.0
        }
    }
}
