import XCTest
@testable import Oscillators

fileprivate let epsilon : Float = 0.000001

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let windowRatio3 : Float = 1.0 / 3.0
fileprivate let sigmaRatio6 : Float = 1.0 / 6.0

final class GeneratorTests: XCTestCase {
    
//    func testConstructor() throws {
//        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .silence, amplitude: 1.0)
//        // test silence and amplitude?
//    }
    
    func testGetNextSample() throws {
        let amplitude : Float = 0.5
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square, amplitude: amplitude)
        let nextSample = generator.getNextSample()
        XCTAssertEqual(nextSample, amplitude, accuracy: epsilon)
    }
    
    func testGetNextSamples1() throws {
        let amplitude : Float = 0.5
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square, amplitude: amplitude)
        let numSamples = 3 * generator.numSamplesInPeriod
        let samples = generator.getNextSamples(numSamples: numSamples)
        XCTAssertEqual(samples.count, numSamples)
        XCTAssertEqual(samples[0], amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 - 1], amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 + 1], -amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[generator.numSamplesInPeriod], amplitude, accuracy: epsilon)
    }

    func testGetNextSamples2() throws {
        let amplitude : Float = 0.5
        let generator = Generator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, waveShape: .square, amplitude: amplitude)
        let numSamples = 3 * generator.numSamplesInPeriod
        var samples = [Float](repeating: 0.0, count: numSamples)
        generator.getNextSamples(samples: &samples)
        XCTAssertEqual(samples[0], amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 - 1], amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[generator.numSamplesInPeriod / 2 + 1], -amplitude, accuracy: epsilon)
        XCTAssertEqual(samples[generator.numSamplesInPeriod], amplitude, accuracy: epsilon)
    }
}
