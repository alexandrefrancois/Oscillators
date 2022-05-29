public protocol GeneratorProtocol {
    
    // Wave shapes
    func setSquareWave()
    func setTriangleWave()
    func setSawWave()
    func setSineWave()
    func setSilence()
    
    // Generation
    func getNextSample() -> Float
    func getNextSamples(numSamples: Int) -> [Float]
    func getNextSamples(samples: inout [Float])
}
