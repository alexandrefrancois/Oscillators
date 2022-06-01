import Foundation

public class Generator : Oscillator, GeneratorProtocol {
    public init(targetFrequency: Float, sampleDuration: Float, waveShape: WaveShape, amplitude: Float = 1.0) {
        super.init(targetFrequency: targetFrequency, sampleDuration: sampleDuration)
        setWaveform(waveShape: waveShape)
        self.amplitude = amplitude
    }

    public func getNextSample() -> Float {
        let nextSample = amplitude * waveformPtr[phaseIdx];
        phaseIdx = (phaseIdx + 1) % waveformPtr.count;
        return nextSample
    }
    
    public func getNextSamples(numSamples: Int) -> [Float] {
        var samples = [Float]()
        var samplesToGet = numSamples
        while samplesToGet > 0 {
            samples.append(amplitude * waveformPtr[phaseIdx])
            samplesToGet -= 1
            phaseIdx = (phaseIdx + 1) % waveformPtr.count
        }
        return samples
    }
    
    public func getNextSamples(samples: inout [Float]) {
        var sampleIdx = 0
        while sampleIdx < samples.count {
            samples[sampleIdx] = amplitude * waveformPtr[phaseIdx]
            sampleIdx += 1
            phaseIdx = (phaseIdx + 1) % waveformPtr.count
        }
    }
}
