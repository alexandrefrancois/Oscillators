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

final class DynamicsTests: XCTestCase {
    func testTimeConstant() throws {
        let t = Dynamics.timeConstant(alpha: DynamicsFixtures.defaultAlpha, sampleDuration: AudioFixtures.sampleDuration44100)
        XCTAssertEqual(t, 0.099999994, accuracy: epsilon)
    }
    func testAlpha() throws {
        let a = Dynamics.alpha(timeConstant: DynamicsFixtures.defaultTimeConstant, sampleDuration: AudioFixtures.sampleDuration44100)
        XCTAssertEqual(a, 0.00022675736, accuracy: epsilon)
    }

}
