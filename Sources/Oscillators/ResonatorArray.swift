import Foundation

/**
    An array of independent resonators
 */
public class ResonatorArray {
    public var alpha: Float // TODO: make a setter that updates all resonators...

    public private(set) var resonators = [Resonator]()
    public private(set) var maxima: [Float]

    // TODO: make initializers with different ways of specifying number of oscillators and frequencies
    public init(targetFrequencies: [Float], sampleDuration: Float, alpha: Float = 0.0001) {
        self.alpha = alpha
        
        // initialize from passed frequencies
        maxima = [Float](repeating: 0, count: targetFrequencies.count)
        
        print("Number of resonators to create: \(targetFrequencies.count)")
        
        // setup an oscillator for each frequency
        for frequency in targetFrequencies {
            resonators.append(Resonator(targetFrequency: frequency, sampleDuration: sampleDuration, alpha: alpha))
        }
    }
    
    public func update(sample: Float) {
        // this can be done in parallel?
        for resonator in resonators {
            resonator.update(sample: sample)
        }
    }
    
    public func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int) {
                for (index, resonator) in resonators.enumerated() {
                    resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
                    self.maxima[index] = resonator.amplitude
                }
//
////        var maxima = [Float](repeating: 0, count: resonators.count)
//        Task {
//            return await withTaskGroup(of: (Int, Float).self) { group in
//                for (index, resonator) in resonators.enumerated() {
//
//                    group.addTask {
//                        resonator.update(frameData: frameData, frameLength: frameLength, sampleStride: sampleStride)
//                        return (index, resonator.amplitude)
//                    }
//
////                    for await (index, amplitude) in group {
////                        self.maxima[index] = amplitude
////                    }
//
//                }
//            }
//        }
////        self.maxima = maxima
    }
}
