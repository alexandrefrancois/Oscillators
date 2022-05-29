import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let windowRatio3 : Float = 1.0 / 3.0
fileprivate let sigmaRatio6 : Float = 1.0 / 6.0

final class GeneratorTests: XCTestCase {
    
    func testConstructor() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .silence)
        XCTAssertEqual(generator.allPhases.count, generator.numSamplesInPeriod)
    }

    func testInitSquareWave() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square)
        XCTAssertEqual(generator.allPhases[0], 1.0)
        XCTAssertEqual(generator.allPhases[generator.numSamplesInPeriod-1], -1.0)
    }
    
    func testInitTriangleWave() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .triangle)
        XCTAssertEqual(generator.allPhases[0], 0.0)
        XCTAssertEqual(generator.allPhases[generator.numSamplesInPeriod/4], 1.0)
        XCTAssertEqual(generator.allPhases[2*(generator.numSamplesInPeriod/4)], 0.0)
        XCTAssertEqual(generator.allPhases[3*(generator.numSamplesInPeriod/4)], -1.0)
    }

    func testInitSawWave() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .saw)
        XCTAssertEqual(generator.allPhases[0], 0.0)
        XCTAssertEqual(generator.allPhases[generator.numSamplesInPeriod/4], 0.5, accuracy: 0.001)
        XCTAssertEqual(generator.allPhases[2*(generator.numSamplesInPeriod/4)], -1.0)
        XCTAssertEqual(generator.allPhases[3*(generator.numSamplesInPeriod/4)], -0.5, accuracy: 0.001)

    }
    
    func testInitSineWave() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .sine)
        XCTAssertEqual(generator.allPhases[0], 0.0)
        XCTAssertEqual(generator.allPhases[generator.numSamplesInPeriod/4], 1.0)
        XCTAssertEqual(generator.allPhases[2*(generator.numSamplesInPeriod/4)], 0.0, accuracy: 0.001)
        XCTAssertEqual(generator.allPhases[3*(generator.numSamplesInPeriod/4)], -1.0)
    }
    
    func testGetNextSample() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square)
        let nextSample = generator.getNextSample()
        XCTAssertEqual(nextSample, 1.0)
    }
    
    func testGetNextSamples1() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square)
        let numSamples = 3 * generator.numSamplesInPeriod
        let samples = generator.getNextSamples(numSamples: numSamples)
        XCTAssertEqual(samples.count, numSamples)
        XCTAssertEqual(samples[0], 1.0)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 - 1], 1.0)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 + 1], -1.0)
        XCTAssertEqual(samples[generator.numSamplesInPeriod], 1.0)
    }

    func testGetNextSamples2() throws {
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square)
        let numSamples = 3 * generator.numSamplesInPeriod
        var samples = [Float](repeating: 0.0, count: numSamples)
        generator.getNextSamples(samples: &samples)
        XCTAssertEqual(samples[0], 1.0)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 - 1], 1.0)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 + 1], -1.0)
        XCTAssertEqual(samples[generator.numSamplesInPeriod], 1.0)
    }

}
