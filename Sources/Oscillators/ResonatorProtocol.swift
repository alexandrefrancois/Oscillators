public protocol ResonatorProtocol {
    var alpha : Float { get set }
    var timeConstant : Float { get }
    var trackedFrequency : Float { get }

    var allPhases: [Float] { get }
    
    /// This function performs an update of the resonator amplitude from a single sample
    func update(sample: Float)
    
    /// This function performs an update of the resonator amplitude from an array of samples
    func update(samples: [Float])
    
    /// This function performs an update of the resonator amplitude from a buffer of samples
    func update(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int)

    /// This function performs an update of the resonator amplitude from a single sample
    func updateAndTrack(sample: Float)
    
    /// This function performs an update of the resonator amplitude from an array of samples
    func updateAndTrack(samples: [Float])
    
    /// This function performs an update of the resonator amplitude from a buffer of samples
    func updateAndTrack(frameData: UnsafeMutablePointer<Float>, frameLength: Int, sampleStride: Int)

}
