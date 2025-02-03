/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

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
    
    func testMusicalPitchFrequencies() throws {
        let frequencies440 = Frequencies.musicalPitchFrequencies(from: 0, to: 116)
        XCTAssertEqual(frequencies440[0], 16.3515968, accuracy: epsilon)
        XCTAssertEqual(frequencies440[9], 27.5, accuracy: epsilon)
        XCTAssertEqual(frequencies440[57], 440.0, accuracy: epsilon)
        XCTAssertEqual(frequencies440[96], 4186.00879, accuracy: epsilon)
        XCTAssertEqual(frequencies440[116], 13289.748, accuracy: epsilon)
        
        let frequencies441 = Frequencies.musicalPitchFrequencies(from: 0, to: 116, tuning: 441.0)
        XCTAssertEqual(frequencies441[0], 16.38876, accuracy: epsilon)
        XCTAssertEqual(frequencies441[9], 27.5625, accuracy: epsilon)
        XCTAssertEqual(frequencies441[57], 441.0, accuracy: epsilon)
        XCTAssertEqual(frequencies441[96], 4195.5225, accuracy: epsilon)
        XCTAssertEqual(frequencies441[116], 13319.952, accuracy: epsilon)
    }
    
    func testLogUniformFrequencies() throws {
        let fMin = Float(32.70)
        let fMax = Float(3950.68)
        let numBins = Int(84)
        let numBinsPerOctaves = Int(12)
        
        let frequencies = Frequencies.logUniformFrequencies(minFrequency: fMin, numBins: numBins, numBinsPerOctave: numBinsPerOctaves)
        
        XCTAssertEqual(frequencies.count, numBins)
        XCTAssertEqual(frequencies[0], fMin)
        XCTAssertEqual(frequencies[numBins-1], fMax, accuracy: 0.01)
        // ratios of consecutive frequencies is constant
        XCTAssertEqual(frequencies[2]/frequencies[1], frequencies[1]/frequencies[0], accuracy: 0.00001)
        XCTAssertEqual(frequencies[numBins-1]/frequencies[numBins-2], frequencies[numBins-2]/frequencies[numBins-3], accuracy: 0.00001)
    }
    
    func testDopplerVelocity() throws {
        let v440441 = Frequencies.dopplerVelocity(observedFrequency: 440, referenceFrequency: 441)
        XCTAssertEqual(v440441, -0.78458047, accuracy: epsilon)
        let v441440 = Frequencies.dopplerVelocity(observedFrequency: 441, referenceFrequency: 440)
        XCTAssertEqual(v441440, 0.78636366, accuracy: epsilon)
    }
}
