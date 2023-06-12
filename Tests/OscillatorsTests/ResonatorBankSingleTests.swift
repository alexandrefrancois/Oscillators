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

final class ResonatorBankSingleTests: XCTestCase {
    func testConstructor() throws {
        let targetFrequencies = FrequenciesFixtures.targetFrequencies
        let resonatorBankSingle = ResonatorBankSingle(targetFrequencies: targetFrequencies,
                                                      sampleDuration: AudioFixtures.sampleDuration44100,
                                                      alpha: DynamicsFixtures.defaultAlpha)
        
        XCTAssertEqual(resonatorBankSingle.alpha, DynamicsFixtures.defaultAlpha)
        XCTAssertNotNil(resonatorBankSingle.allPhasesPtr)
//        print("allPhasesPtr base Address: \(String(describing: resonatorBankSingle.allPhasesPtr.baseAddress)) = \(Int(bitPattern: resonatorBankSingle.allPhasesPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonatorBankSingle.allPhasesPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonatorBankSingle.allPhasesPtr.count, resonatorBankSingle.sumSamplesPerPeriod)

        XCTAssertNotNil(resonatorBankSingle.waveformsPtr)
//        print("kernelsPtr base Address: \(String(describing: resonatorBankSingle.waveformsPtr.baseAddress)) = \(Int(bitPattern: resonatorBankSingle.waveformsPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonatorBankSingle.waveformsPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonatorBankSingle.waveformsPtr.count, resonatorBankSingle.sumSamplesPerPeriod)

        XCTAssertNotNil(resonatorBankSingle.leftTermPtr)
//        print("leftTermPtr base Address: \(String(describing: resonatorBankSingle.leftTermPtr.baseAddress)) = \(Int(bitPattern: resonatorBankSingle.leftTermPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonatorBankSingle.leftTermPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonatorBankSingle.leftTermPtr.count, resonatorBankSingle.sumSamplesPerPeriod)

        XCTAssertNotNil(resonatorBankSingle.rightTermPtr)
//        print("rightTermPtr base Address: \(String(describing: resonatorBankSingle.rightTermPtr.baseAddress)) = \(Int(bitPattern: resonatorBankSingle.rightTermPtr.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonatorBankSingle.rightTermPtr.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonatorBankSingle.rightTermPtr.count, resonatorBankSingle.sumSamplesPerPeriod)
    }
    
    func testUpdateAllPhases() throws {
        let resonatorBankSingle = ResonatorBankSingle(targetFrequencies: FrequenciesFixtures.targetFrequencies,
                                                      sampleDuration: AudioFixtures.sampleDuration44100,
                                                      alpha: 1.0)
        resonatorBankSingle.update(sample: 1.0)
        for i in 0..<resonatorBankSingle.sumSamplesPerPeriod {
            XCTAssertEqual(resonatorBankSingle.allPhasesPtr[i], resonatorBankSingle.waveformsPtr[i])
        }
        resonatorBankSingle.update(sample: 0.0)
        for i in 0..<resonatorBankSingle.sumSamplesPerPeriod {
            XCTAssertEqual(resonatorBankSingle.allPhasesPtr[i], 0.0)
        }
    }
}
