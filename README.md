# Oscillators

`Oscillators` is a Swift package for sinusoidal synthesis and low-latency
frequency analysis on Apple platforms. It contains:

- Recursive sinusoidal oscillators.
- Fixed-frequency resonators and resonator banks.
- Tracking resonators that adapt their resonant frequency to an input component.
- Scalar reference implementations and Accelerate-backed vector implementations.
- C++ implementations exposed to Swift through Objective-C++ wrappers.
- Frequency-scale and dynamics utilities.

The resonators implement the ideas behind
[Resonate](http://alexandrefrancois.org/Resonate): estimating perceptually
relevant spectral information at the input signal's sample resolution without
an FFT frame.

## Requirements

The package manifest declares:

- Swift tools 5.6 or later.
- macOS 10.15 or later.
- iOS 15 or later.
- C++17 for the C++ target.

Both products are Apple-platform implementations. The Swift vectorized code
uses Accelerate, and the C++ product uses Objective-C++ wrappers with Apple
frameworks. The Swift product depends on
[swift-atomics](https://github.com/apple/swift-atomics).

## Installation

Add the package in Xcode, or add it to `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/alexandrefrancois/Oscillators.git",
        from: "5.0.0"
    )
]
```

Then add the product needed by your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Oscillators", package: "Oscillators")
    ]
)
```

Add the `OscillatorsCpp` product when importing the Objective-C++ bridge types.

## Quick Start

### Generate a sinusoid

`Oscillator` emits cosine samples and preserves phase between calls:

```swift
import Oscillators

let oscillator = Oscillator(
    frequency: 440,
    sampleRate: 48_000,
    amplitude: 0.5
)

let frame = oscillator.getNextSamples(numSamples: 512)
```

Changing `frequency` or `amplitude` affects subsequent samples.

### Analyze fixed frequencies

Use `ResonatorBankVec` for a bank stored and updated as contiguous vectors:

```swift
import Oscillators

let sampleRate: Float = 48_000
let frequencies = Frequencies.logUniformFrequencies(
    minFrequency: 55,
    numBins: 84,
    numBinsPerOctave: 12
)
let alphas = ResonatorBankVec.alphasHeuristic(
    frequencies: frequencies,
    sampleRate: sampleRate
)

let bank = ResonatorBankVec(
    frequencies: frequencies,
    alphas: alphas,
    sampleRate: sampleRate
)

bank.update(frame: frame)

let powers = bank.powers
let amplitudes = bank.amplitudes
let phases = bank.phases
```

The output arrays use the same ordering as `frequencies`. Call `reset()` to
clear accumulated state and restore the phasors.

### Track changing frequencies

`TrackingResonatorBankVec` starts at a set of natural frequencies and adjusts
each resonant frequency when its response is strong enough:

```swift
let trackingBank = TrackingResonatorBankVec(
    naturalFrequencies: frequencies,
    alphas: alphas,
    gammas: nil,
    sampleRate: sampleRate
)

trackingBank.update(frame: frame)

let detectedPowers = trackingBank.powers
let trackedFrequencies = trackingBank.resonantFrequencies
```

When `betas` is omitted it defaults to `alphas`. When `gammas` is `nil`, the
vector tracking bank uses half of each alpha.

## Choosing an Implementation

| Type | Role | Storage and execution |
| --- | --- | --- |
| `Oscillator` | Cosine signal generation | Scalar Swift state |
| `Resonator` | One fixed-frequency analyzer | Scalar Swift state |
| `TrackingResonator` | One self-tuning analyzer | Scalar Swift state |
| `ResonatorBankArray` | Fixed-frequency bank | Array of `Resonator` instances; sequential or synchronous concurrent update |
| `ResonatorBankVec` | Fixed-frequency bank | Structure-of-arrays storage using Accelerate |
| `TrackingResonatorBankArray` | Self-tuning bank | Array of `TrackingResonator` instances; sequential or synchronous concurrent update |
| `TrackingResonatorBankVec` | Self-tuning bank | Structure-of-arrays storage using Accelerate and SIMD |

`Phasor` is the shared recursive phase implementation behind the scalar types.
It has no public initializer, so client code normally starts with
`Oscillator`, `Resonator`, or `TrackingResonator`.

The array banks expose their resonator instances and are the clearest choice
when individual configuration or inspection matters. The vector banks batch
work across all frequencies and avoid per-resonator object dispatch. Measure
both with your frequency count, frame size, and target hardware before choosing
solely for performance.

The `OscillatorsCpp` product exposes these bridge classes to Swift:

- `PhasorCpp`
- `ResonatorCpp`
- `ResonatorBankCpp`
- `ResonatorBankVecCpp`
- `TrackingResonatorCpp`
- `TrackingResonatorBankCpp`
- `TrackingResonatorBankVecCpp`

Their interfaces intentionally resemble the Swift implementations so results
and performance can be compared.

## Processing Buffers

Scalar resonators accept one sample, a `[Float]`, or a raw buffer. Vector banks
expose frame and raw-buffer updates. For interleaved buffers, pass the address
of the first channel sample, the number of frames to process, and the distance
between consecutive samples for that channel:

```swift
var interleavedStereo = [Float](repeating: 0, count: 1_024)
let frameCount = interleavedStereo.count / 2

interleavedStereo.withUnsafeMutableBufferPointer { buffer in
    guard let firstSample = buffer.baseAddress else { return }

    bank.update(
        frameData: firstSample,
        frameLength: frameCount,
        sampleStride: 2
    )
}
```

The raw-pointer overloads read the buffer but currently require a mutable
pointer. The caller is responsible for keeping the pointer valid and ensuring
that `frameLength` and `sampleStride` remain within the allocation.

## Model and Parameters

A phasor stores a unit complex value `Z` and advances it recursively:

```text
theta = -2 pi f / sampleRate
Z <- Z * W
W = cos(theta) + i sin(theta)
```

An oscillator returns the real component of `Z`, scaled by its amplitude.
Periodic normalization limits floating-point drift.

A resonator maintains a complex exponentially weighted moving average:

```text
R <- (1 - alpha) * R + alpha * sample * Z
```

A second moving average controlled by `beta` smooths the response. `gamma`
controls phase-derivative smoothing in a fixed resonator and frequency
adaptation in a tracking resonator. Smaller coefficients respond more slowly;
larger coefficients respond more quickly.

Common outputs are:

- `power`: squared magnitude of the smoothed complex response.
- `amplitude`: square root of `power`.
- `phase`: angle of the smoothed complex response, in radians.
- `instantaneousFrequency`: phase-derived estimate from a fixed resonator.
- `resonantFrequency`: current self-tuned frequency of a tracking resonator.
- `naturalFrequency`: fallback frequency of a tracking resonator.

`Dynamics.alpha(timeConstant:sampleRate:)` and
`Dynamics.timeConstant(alpha:sampleRate:)` convert between EWMA coefficients
and time constants. `Frequencies` provides equal-tempered, logarithmic, mel,
Doppler, and response-equalization helpers.

## Input Contracts and Runtime Behavior

The current interfaces do not validate all inputs. Callers should provide:

- Positive, finite sample rates and time constants.
- Positive `sampleStride` values.
- Matching counts for frequencies, alphas, betas, and gammas.
- At least one frequency for vector banks.
- Smoothing coefficients appropriate for an EWMA, normally in `0...1`.

Instances are mutable state machines. Do not update the same instance
concurrently. `updateConcurrent` partitions one bank across four synchronous
`DispatchQueue.concurrentPerform` chunks; it returns only after all resonators
finish and should not be assumed to be real-time safe.

Changing a scalar phasor's `sampleRate` currently preserves its angular
increment, not its frequency in hertz. Set `frequency` again after changing
`sampleRate` when the hertz value must remain constant.

Reading bank results such as `powers`, `amplitudes`, and `phases` creates new
Swift arrays. Keep those reads outside allocation-sensitive audio callbacks
unless profiling shows that the cost is acceptable.

## Architecture

```text
Package.swift
Sources/
  Oscillators/       Swift scalar, array-bank, and Accelerate implementations
  OscillatorsCpp/    C++ implementations and Objective-C++ Swift bridges
Tests/
  OscillatorsTests/  XCTest behavior and Swift/C++ parity tests
```

The scalar implementations act as readable reference models. The vector
implementations reproduce the same state updates over split-complex buffers.
Cross-implementation tests compare key Swift and C++ results within floating
point tolerances.

## Development

Build and run the test suite with:

```sh
swift test
```

The suite covers utilities, oscillator stability, scalar resonator responses,
fixed bank updates, selected concurrent paths, resets, tracking behavior, and
several Swift/C++ parity cases.

## License

Copyright (c) 2022-2026 Alexandre R. J. François.

Released under the [MIT License](LICENSE).
