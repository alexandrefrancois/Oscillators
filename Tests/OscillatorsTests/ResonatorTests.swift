import XCTest
@testable import Oscillators

fileprivate let sampleDuration44100 : Float = 1.0 / 44100.0

final class ResonatorTests: XCTestCase {
    
    func testConstructor() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 0.0001)
        
        XCTAssertEqual(resonator.alpha, 0.0001)
        
        XCTAssertNotNil(resonator.allPhasesPtr)
        print("allPhasesPtr base Address: \(String(describing: resonator.allPhasesPtr!.baseAddress)) = \(Int(bitPattern: resonator.allPhasesPtr!.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonator.allPhasesPtr!.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonator.allPhasesPtr!.count, resonator.numSamplesInWaveform)

        XCTAssertNotNil(resonator.leftTermPtr)
        print("leftTermPtr base Address: \(String(describing: resonator.leftTermPtr!.baseAddress)) = \(Int(bitPattern: resonator.leftTermPtr!.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonator.leftTermPtr!.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonator.leftTermPtr!.count, resonator.numSamplesInWaveform)
        
        XCTAssertNotNil(resonator.rightTermPtr)
        print("rightTermPtr base Address: \(String(describing: resonator.rightTermPtr!.baseAddress)) = \(Int(bitPattern: resonator.rightTermPtr!.baseAddress))")
        XCTAssertEqual(Int(bitPattern: resonator.rightTermPtr!.baseAddress) % MemoryLayout<Float>.alignment, 0)
        XCTAssertEqual(resonator.rightTermPtr!.count, resonator.numSamplesInWaveform)
    }
    
    func testUpdateAllPhases() throws {
        let resonator = Resonator(targetFrequency: 440.0, sampleDuration: sampleDuration44100, alpha: 1.0)
        resonator.updateAllPhases(sample: 1.0)
        for i in 0..<resonator.numSamplesInWaveform {
            XCTAssertEqual(resonator.allPhasesPtr![i], resonator.waveformPtr[i])
        }
        resonator.updateAllPhases(sample: 0.0)
        for i in 0..<resonator.numSamplesInWaveform {
            XCTAssertEqual(resonator.allPhasesPtr![i], 0.0)
        }
    }
    
    func testUpdatePerf() throws {
        let resonator = Resonator(targetFrequency: 10.0, sampleDuration: sampleDuration44100, alpha: 0.001)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        measure {
            resonator.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        }
        frame.deallocate()
    }
    
    func testUpdateSafePerf() throws {
        let resonator = ResonatorSafe(targetFrequency: 10.0, sampleDuration: sampleDuration44100, alpha: 0.001)
        let frame = UnsafeMutablePointer<Float>.allocate(capacity: 1024)
        frame.initialize(repeating: 0.5, count: 1024)
        measure {
            resonator.update(frameData: frame, frameLength: 1024, sampleStride: 1)
        }
        frame.deallocate()

    }
}
