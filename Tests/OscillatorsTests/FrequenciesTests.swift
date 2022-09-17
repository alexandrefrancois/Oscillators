/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

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

fileprivate let epsilon : Float = 0.000001

final class FrequenciesTests: XCTestCase {
    
    func testClosestFrequency() throws {
        let samplingRate : Int = 44100
        let sampleDuration : Float = 1.0 / Float(samplingRate)
        let frequency1 = Frequencies.closestFrequency(targetFrequency: 441.0, sampleDuration: sampleDuration)
        XCTAssertEqual(frequency1, 441.0, accuracy: epsilon)
        XCTAssertEqual(Int(1.0 / (frequency1 * sampleDuration)), 100)
        let frequency2 = Frequencies.closestFrequency(targetFrequency: 440.0, sampleDuration: sampleDuration)
        XCTAssertEqual(frequency2, 441.0, accuracy: epsilon)
        XCTAssertEqual(Int(1.0 / (frequency2 * sampleDuration)), 100)
    }

    func testDopplerVelocity() throws {
        let v440441 = Frequencies.dopplerVelocity(observedFrequency: 440, referenceFrequency: 441)
        XCTAssertEqual(v440441, -0.78458047, accuracy: epsilon)
        let v441440 = Frequencies.dopplerVelocity(observedFrequency: 441, referenceFrequency: 440)
        XCTAssertEqual(v441440, 0.78636366, accuracy: epsilon)
    }
}
