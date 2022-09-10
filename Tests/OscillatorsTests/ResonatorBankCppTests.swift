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
@testable import OscillatorsCpp

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0
fileprivate let defaultAlpha : Float = 0.0005

fileprivate var targetFrequencies: [Float] = [16.351501, 17.32129, 18.35206, 19.453022, 20.607477, 21.831684, 23.125328, 24.5, 25.971731, 27.510916, 29.14739, 30.882353, 32.715134, 34.66981, 36.719402, 38.923214, 41.214954, 43.66337, 46.27492, 49.0, 51.943462, 55.05618, 58.333336, 61.764706, 65.43027, 69.33962, 73.5, 77.91519, 82.42991, 87.32674, 92.647064, 98.0, 104.00944, 110.25, 116.66667, 123.52941, 130.86053, 138.67924, 147.0, 155.83038, 165.16853, 175.0, 185.29413, 196.0, 208.01888, 220.5, 233.33334, 247.7528, 262.5, 277.3585, 294.0, 312.76596, 331.57895, 350.0, 370.58826, 393.75003, 416.03775, 441.0, 469.14896, 495.5056, 525.0, 558.22784, 588.0, 630.0, 668.1818, 700.0, 747.4576, 787.50006, 832.0755, 882.0, 938.2979, 1002.27277, 1050.0, 1130.7693, 1191.892, 1260.0, 1336.3636, 1422.5807, 1520.6897, 1575.0001, 1696.1538, 1764.0, 1917.3914, 2004.5455, 2100.0, 2321.0527, 2450.0, 2594.1177, 2756.25, 2940.0, 3150.0002, 3392.3076, 3675.0002, 4009.091, 4410.0, 4900.0, 5512.5, 6300.0005, 7350.0005, 8820.0]

final class ResonatorBankCppTests: XCTestCase {
    func testConstructor() throws {
        let resonatorBankCpp = ResonatorBankCpp(numResonators: (Int32)(targetFrequencies.count), targetFrequencies: &targetFrequencies, sampleDuration: sampleDuration44100, alpha: defaultAlpha)
        guard let resonatorBankCpp = resonatorBankCpp else { return XCTAssert(false) }

        XCTAssertEqual(resonatorBankCpp.alpha(), defaultAlpha)
        XCTAssertEqual((Int)(resonatorBankCpp.numResonators()), targetFrequencies.count)
    }
        
    // This test is not really meaningful
//    func testUpdatePerf() async throws {
//        let resonatorBankCpp = ResonatorBankCpp(numResonators: (Int32)(targetFrequencies.count), targetFrequencies: &targetFrequencies, sampleDuration: sampleDuration44100, alpha: defaultAlpha)
//        guard let resonatorBankCpp = resonatorBankCpp else { return XCTAssert(false) }
//        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
//        frame.initialize(repeating: 0.5, count: 1024)
//        measure {
//            resonatorBankCpp.update(frameData: frame, frameLength: 1024, sampleStride: 1)
//        }
//        frame.deallocate()
//    }

}
