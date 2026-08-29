/**
MIT License

Copyright (c) 2022-2026 Alexandre R. J. Francois

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

import XCTest
@testable import Oscillators
import OscillatorsCpp

final class ResonatorTests: XCTestCase {
    private let epsilon : Float = 1e-6

    func testConstructor() throws {
        let resonator = Resonator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, alpha: DynamicsFixtures.defaultAlpha)
        
        XCTAssertEqual(resonator.alpha, DynamicsFixtures.defaultAlpha)
    }
    
    func testSetAlpha() throws {
        var alpha: Float = 0.99
        let resonator = Resonator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, alpha: alpha)
        XCTAssertEqual(resonator.alpha, alpha)
        XCTAssertEqual(resonator.omAlpha, 1.0-alpha)

        alpha = 0.11
        resonator.alpha = alpha
        XCTAssertEqual(resonator.omAlpha, 1.0-alpha)
    }
    
    func testUpdateWithSample() throws {
        let resonator = Resonator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, alpha: 1.0)
        let expectedC = resonator.Zc
        let expectedS = resonator.Zs
        resonator.updateWithSample(1.0)
        XCTAssertEqual(resonator.c, expectedC, accuracy: epsilon)
        XCTAssertEqual(resonator.s, expectedS, accuracy: epsilon)
        resonator.updateWithSample(0.0)
        XCTAssertEqual(resonator.s, 0.0)
        XCTAssertEqual(resonator.c, 0.0)
    }
        
    func testImpulseResponse() {
        let N = 128
        let resonator = Resonator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, alpha: 0.9, beta: 0.9, gamma: 0.9)
        let impulse = SignalFixtures.makeImpulse(count: N)
        var outputs = [Float]()
        for x in impulse { resonator.updateWithSample(x); outputs.append(resonator.amplitude) }
        let maxAbs = outputs.map { abs($0) }.max() ?? 0
        XCTAssertGreaterThan(maxAbs, outputs[1..<N].map { abs($0) }.max() ?? 0)
    }
    
    func testStepResponse() {
        let N = 128
        let resonator = Resonator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, alpha: 0.95, beta: 0.95, gamma: 0.95)
        let step = SignalFixtures.makeStep(count: N, value: 1.0)
        var outputs = [Float]()
        for x in step { resonator.updateWithSample(x); outputs.append(resonator.amplitude) }
        XCTAssertGreaterThan(outputs[2], outputs[0])
        XCTAssertLessThan(abs(outputs[N-1] - outputs[N-2]), 0.01) // Nearly settled
    }
    
    func testSinusoidalInput() {
        let N = 256
        let f0: Float = 440.0
        let sr: Float = AudioFixtures.defaultSampleRate
        let resonator = Resonator(frequency: f0, sampleRate: sr, alpha: 0.95, beta: 0.95, gamma: 0.95)
        let sine = SignalFixtures.makeSine(count: N, freq: f0, sampleRate: sr)
        var outputs = [Float]()
        for x in sine { resonator.updateWithSample(x); outputs.append(resonator.amplitude) }
        XCTAssertGreaterThan(outputs[N/2], outputs[0])
    }
    
    func testConvergence() {
        let N = 200
        let resonator = Resonator(frequency: 440.0, sampleRate: AudioFixtures.defaultSampleRate, alpha: 0.7, beta: 0.7, gamma: 0.7)
        let step = SignalFixtures.makeStep(count: N, value: 1.0)
        for x in step { resonator.updateWithSample(x) }
        let amp_prev = resonator.amplitude
        let phaseDeriv_prev = resonator.deltaPhase
        resonator.updateWithSample(1.0)
        let amp_now = resonator.amplitude
        let phaseDeriv_now = resonator.deltaPhase
        // Check stabilization
        XCTAssertLessThan(abs(amp_now - amp_prev), 0.001)
        XCTAssertLessThan(abs(phaseDeriv_now - phaseDeriv_prev), 0.001)
    }
    
    func testCrossValidationWithCpp() {
        let N = 128
        let f0: Float = 440.0
        let alpha: Float = 0.9, beta: Float = 0.9, gamma: Float = 0.9
        let sr: Float = AudioFixtures.defaultSampleRate
        let input = SignalFixtures.makeSine(count: N, freq: f0, sampleRate: sr)
        let swiftRes = Resonator(frequency: f0, sampleRate: sr, alpha: alpha, beta: beta, gamma: gamma)
        guard let cppRes = ResonatorCpp(frequency: f0, sampleRate: sr, alpha: alpha, beta: beta, gamma: gamma) else {
            XCTFail("Cpp Resonator could not be instantiated"); return
        }
        for x in input {
            swiftRes.updateWithSample(x)
            cppRes.updateWithSample(value: x)
            XCTAssertEqual(swiftRes.c, cppRes.c(), accuracy: epsilon)
            XCTAssertEqual(swiftRes.s, cppRes.s(), accuracy: epsilon)
        }
    }

    func testRawBufferStrideTreatsFrameLengthAsFrameCount() {
        let frameLength = 96
        let f0: Float = 440.0
        let alpha: Float = 0.9, beta: Float = 0.9, gamma: Float = 0.9
        let sampleRate = AudioFixtures.defaultSampleRate
        let channelSamples = SignalFixtures.makeSine(count: frameLength, freq: f0, sampleRate: sampleRate)
        var interleaved = channelSamples.flatMap { [$0, Float(-0.25)] }

        let swiftReference = Resonator(frequency: f0, sampleRate: sampleRate, alpha: alpha, beta: beta, gamma: gamma)
        let swiftStrided = Resonator(frequency: f0, sampleRate: sampleRate, alpha: alpha, beta: beta, gamma: gamma)

        swiftReference.update(samples: channelSamples)
        interleaved.withUnsafeMutableBufferPointer { buffer in
            swiftStrided.update(
                frameData: buffer.baseAddress!,
                frameLength: frameLength,
                sampleStride: 2
            )
        }

        XCTAssertEqual(swiftStrided.amplitude, swiftReference.amplitude, accuracy: 1e-5)
        XCTAssertEqual(swiftStrided.phase, swiftReference.phase, accuracy: 1e-5)

        guard let cppReference = ResonatorCpp(
            frequency: f0,
            sampleRate: sampleRate,
            alpha: alpha,
            beta: beta,
            gamma: gamma
        ), let cppStrided = ResonatorCpp(
            frequency: f0,
            sampleRate: sampleRate,
            alpha: alpha,
            beta: beta,
            gamma: gamma
        ) else {
            XCTFail("Cpp Resonator could not be instantiated")
            return
        }

        channelSamples.forEach { cppReference.updateWithSample(value: $0) }
        interleaved.withUnsafeMutableBufferPointer { buffer in
            cppStrided.update(
                frameData: buffer.baseAddress!,
                frameLength: Int32(frameLength),
                sampleStride: 2
            )
        }

        XCTAssertEqual(cppStrided.amplitude(), cppReference.amplitude(), accuracy: 1e-5)
        XCTAssertEqual(cppStrided.phase(), cppReference.phase(), accuracy: 1e-5)
    }
}
