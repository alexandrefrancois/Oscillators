public protocol GeneratorProtocol {
    var amplitude : Float { get set }
    func getNextSample() -> Float
    func getNextSamples(numSamples: Int) -> [Float]
    func getNextSamples(samples: inout [Float])
}
