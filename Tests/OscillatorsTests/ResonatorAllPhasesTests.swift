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

final class ResonatorAllPhasesTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = ResonatorAllPhases(targetFrequency: 440.0,
                                  sampleDuration: AudioFixtures.sampleDuration44100,
                                  alpha: DynamicsFixtures.defaultAlpha)
        
        XCTAssertEqual(resonator.alpha, DynamicsFixtures.defaultAlpha)
        
        XCTAssertNotNil(resonator.allPhasesPtr)
//        print("allPhasesPtr base Address: \(String(describing: resonator.allPhasesPtr!.baseAddress)) = \(Int(bitPattern: resonator.allPhasesPtr!.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonator.allPhasesPtr!.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonator.allPhasesPtr!.count, resonator.numSamplesInWaveform)

        XCTAssertNotNil(resonator.leftTermPtr)
//        print("leftTermPtr base Address: \(String(describing: resonator.leftTermPtr!.baseAddress)) = \(Int(bitPattern: resonator.leftTermPtr!.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonator.leftTermPtr!.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonator.leftTermPtr!.count, resonator.numSamplesInWaveform)
        
        XCTAssertNotNil(resonator.rightTermPtr)
//        print("rightTermPtr base Address: \(String(describing: resonator.rightTermPtr!.baseAddress)) = \(Int(bitPattern: resonator.rightTermPtr!.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonator.rightTermPtr!.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonator.rightTermPtr!.count, resonator.numSamplesInWaveform)
    }
    
    func testSetAlpha() throws {
        var alpha: Float = 0.99
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100, alpha: alpha)
        XCTAssertEqual(resonator.alpha, alpha)
        XCTAssertEqual(resonator.omAlpha, 1.0-alpha)

        alpha = 0.11
        resonator.alpha = alpha
        XCTAssertEqual(resonator.omAlpha, 1.0-alpha)
    }
    
    func testUpdateAllPhases() throws {
        let resonator = ResonatorAllPhases(targetFrequency: 440.0, sampleDuration: AudioFixtures.sampleDuration44100, alpha: 1.0)
        resonator.updateAllPhases(sample: 1.0)
        for i in 0..<resonator.numSamplesInWaveform {
            XCTAssertEqual(resonator.allPhasesPtr![i], resonator.waveformPtr[i])
        }
        resonator.updateAllPhases(sample: 0.0)
        for i in 0..<resonator.numSamplesInWaveform {
            XCTAssertEqual(resonator.allPhasesPtr![i], 0.0)
        }
    }
}
