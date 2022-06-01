public protocol OscillatorProtocol {
    var sampleDuration : Float { get }
    var frequency : Float { get }
    var amplitude : Float { get }
    var waveform : [Float] { get }

    // Wave shapes
    func setSquareWave()
    func setTriangleWave()
    func setSawWave()
    func setSineWave()
    func setSilence()
}
