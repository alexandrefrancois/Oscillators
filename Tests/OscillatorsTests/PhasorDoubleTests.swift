//
//  PhasorDoubleTests.swift
//  Oscillators
//
//  Created by Alexandre Francois on 01/08/2026.
//


import XCTest
@testable import Oscillators

fileprivate let epsilon : Double = 0.00000001
fileprivate let twoPi = Double.pi * 2.0

final class PhasorDoubleTests: XCTestCase {
    
    func testConstructor() throws {
        let frequency = Double(440.0)
        let sampleRate = Double(44100.0)
        
        let phasor = PhasorDouble(frequency: frequency, sampleRate: sampleRate)
        
        XCTAssertEqual(phasor.sampleRate, Double(44100.0))
        XCTAssertEqual(phasor.frequency, frequency)
        XCTAssertEqual(phasor.sampleRate, sampleRate)
    }
    
    func testUpdateMultiplier() throws {
        let frequency = Double(440.0)
        let sampleRate = Double(44100.0)

        let phasor = PhasorDouble(frequency: frequency, sampleRate: sampleRate)

        // initial values
        var omega = -twoPi * frequency / sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))
        
        // change frequency
        phasor.frequency = Double(880.0)
        omega = -twoPi * phasor.frequency / phasor.sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega))
        XCTAssertEqual(phasor.Ws, sin(omega))
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))

        // change sampleRate
        phasor.sampleRate = Double(48000.0)
        omega = -twoPi * phasor.frequency / phasor.sampleRate
        XCTAssertEqual(phasor.Wc, cos(omega), accuracy: epsilon)
        XCTAssertEqual(phasor.Ws, sin(omega), accuracy: epsilon)
        XCTAssertEqual(phasor.Wcps, cos(omega)+sin(omega))

    }
    
    func testPhasor() throws {
        let frequencies: [Double] = [10.0, 27.5, 55.0, 110.0, 220.0, 440.0, 880.0, 1_000.0, 1_760.0, 2_500.0, 4_410.0, 8_000.0]
        let sampleRate = Double(44100.0)
        let sampleCount = Int(sampleRate)
        let maximumFrequencyError: Double = 0.01
        
        for frequency in frequencies {
            let phasor = PhasorDouble(frequency: frequency, sampleRate: sampleRate)
            var stabilizeCount: Int = 0
            
            for i in 0..<sampleCount {
                phasor.incrementPhase()
//                if i % 1024 == 0 {
//                    phasor.stabilize()
//                }
                stabilizeCount = max(stabilizeCount, phasor.stabilizeIfNeeded())
            }
            
            let expectedPhase = -twoPi * frequency * Double(sampleCount) / sampleRate
            let expectedZc = cos(expectedPhase)
            let expectedZs = sin(expectedPhase)
            let dot = phasor.Zc * expectedZc + phasor.Zs * expectedZs
            let cross = expectedZc * phasor.Zs - expectedZs * phasor.Zc
            let phaseError = abs(atan2(cross, dot))
            let frequencyError = phaseError * sampleRate / (twoPi * Double(sampleCount))
            
            XCTAssertEqual(phasor.magnitude, 1.0, accuracy: epsilon, "frequency: \(frequency), magnitude error: \(phasor.magnitude - 1.0)")
            XCTAssertLessThanOrEqual(frequencyError, maximumFrequencyError, "frequency: \(frequency), frequency error: \(frequencyError) Hz")
            
            print(stabilizeCount, phasor.magnitude)
        }
    }

}
