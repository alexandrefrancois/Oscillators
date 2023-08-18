/**
MIT License

Copyright (c) 2022-2023 Alexandre R. J. Francois

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

fileprivate let epsilon : Float = 0.0001
fileprivate let twoPi = Float.pi * 2.0

final class SineLUTTests: XCTestCase {
    
    func testConstructor() throws {
        let sineLUT = SineLUT.shared
        let delta = twoPi / Float(SineLUT.lutSize)
        for index in 0..<SineLUT.lutSize {
            let expected = sin(delta * Float(index))
            XCTAssertEqual(sineLUT.lutPtr[index], expected, accuracy: epsilon)
        }
        XCTAssertEqual(sineLUT.lutPtr[SineLUT.lutSize], 0)
    }
    
    func testSin() throws {
        let sineLUT = SineLUT.shared
        
        let f : Float = 440.0
        let s : Float = 44100.0
        
        let phaseIncrement = SineLUT.phaseIncrement(frequency: f, samplingRate: s)
        let angleIncrement = twoPi * f / s
        
        var phaseIdx : Float = 0.0

        for i in 0...2050 {
            let theta = Float(i) * angleIncrement
            XCTAssertEqual(sineLUT.sin(phaseIdx: phaseIdx), sin(theta), accuracy: epsilon)
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        }
    }
    
    func testCos() throws {
        let sineLUT = SineLUT.shared
        
        let f : Float = 440.0
        let s : Float = 44100.0
        
        let phaseIncrement = SineLUT.phaseIncrement(frequency: f, samplingRate: s)
        let angleIncrement = twoPi * f / s
        
        var phaseIdx : Float = 0.0

        for i in 0...2050 {
            let theta = Float(i) * angleIncrement
            XCTAssertEqual(sineLUT.cos(phaseIdx: phaseIdx), cos(theta), accuracy: epsilon)
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        }
    }
    
    func testSinCos() throws {
        let sineLUT = SineLUT.shared
        
        let f : Float = 440.0
        let s : Float = 44100.0
        
        let phaseIncrement = SineLUT.phaseIncrement(frequency: f, samplingRate: s)
        let angleIncrement = twoPi * f / s
        
        var phaseIdx : Float = 0.0

        for i in 0...2050 {
            let theta = Float(i) * angleIncrement
            let (s,c) = sineLUT.sinCos(phaseIdx: phaseIdx)
            XCTAssertEqual(s, sin(theta), accuracy: epsilon)
            XCTAssertEqual(c, cos(theta), accuracy: epsilon)
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        }
    }
    
    func testSinWithGenerator() throws {
        let sineLUT = SineLUT.shared
        
        let f : Float = 441.0
        let s : Float = 44100.0

        let phaseIncrement = SineLUT.phaseIncrement(frequency: f, samplingRate: s)
        var phaseIdx : Float = 0.0

        let d : Float = 1.0 / s
        let generator = Generator(targetFrequency: 441.0, sampleDuration: d, waveShape: .sine)
        
        for _ in 0...2050 {
            XCTAssertEqual(sineLUT.sin(phaseIdx: phaseIdx), generator.getNextSample(), accuracy: epsilon)
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
        }
    }
    
    func testCosPhaseIndex() throws {
        let sineLUT = SineLUT.shared

        let f : Float = 440.0
        let s : Float = 44100.0

        let phaseIncrement = SineLUT.phaseIncrement(frequency: f, samplingRate: s)
        var phaseIdx : Float = 0.0
        var cosPhaseIdx = SineLUT.cosPhaseIndex(phaseIdx: phaseIdx)
        
        let angleIncrement = twoPi * f / s

        for i in 0...2050 {
            let theta = Float(i) * angleIncrement
            XCTAssertEqual(sineLUT.sin(phaseIdx: phaseIdx), sin(theta), accuracy: epsilon)
            phaseIdx = SineLUT.nextPhaseIndex(phaseIndex: phaseIdx, phaseIncrement: phaseIncrement)
            XCTAssertEqual(sineLUT.sin(phaseIdx: cosPhaseIdx), cos(theta), accuracy: epsilon)
            cosPhaseIdx = SineLUT.nextPhaseIndex(phaseIndex: cosPhaseIdx, phaseIncrement: phaseIncrement)
        }

    }
}
